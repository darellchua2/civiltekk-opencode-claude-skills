# syntax=docker/dockerfile:1

# ── Stage 1: node ────────────────────────────────────────────────────────────
# Toolchain source only. The runtime stage copies /usr/local (node, npm,
# corepack) from this stage instead of installing Node via apt or nodesource.
FROM node:24-bookworm-slim AS node

# ── Stage 2: python-deps ─────────────────────────────────────────────────────
# Builds the venv the runtime stage copies. MUST use the same base as the
# runtime stage so the venv's interpreter path and glibc match after the copy
# (venvs do not relocate).
FROM python:3.12-slim-bookworm AS python-deps

RUN python3 -m venv /opt/python-env

# #487: bake the upstream markitdown MCP server into the venv — pulled from
# PyPI with the same exact pin as deploy/setup.sh (upstream publishes only
# alphas, so an exact pre-release pin is required; bump both together —
# these two files are the only pin surfaces since #474).
# Do NOT use uv - it is not installed in this image.
RUN /opt/python-env/bin/pip install --no-cache-dir \
    "openpyxl>=3.1.0" \
    "pandas>=3.0.0" \
    "pdfplumber>=0.11.0" \
    "requests>=2.32.0" \
    "numpy>=2.0.0" \
    "fastapi>=0.115.0" \
    "markitdown-mcp==0.0.1a7"

# ── Stage 3: runtime ─────────────────────────────────────────────────────────
FROM python:3.12-slim-bookworm

LABEL org.opencontainers.image.title="civiltekk-opencode-claude-skills" \
      org.opencontainers.image.description="OpenCode standalone web endpoint - configurable agent/skill runner" \
      org.opencontainers.image.source="https://github.com/darellchua2/civiltekk-opencode-claude-skills"

ARG OPENCODE_VERSION=2.0.8

ENV DEBIAN_FRONTEND=noninteractive

# Runtime tools only — no python3-pip/python3-venv (the venv arrives prebuilt
# from python-deps) and no build tooling.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        ripgrep \
        openssh-client \
        chromium \
        fonts-liberation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local /usr/local
COPY --from=python-deps /opt/python-env /opt/python-env

ENV PATH="/opt/python-env/bin:${PATH}" \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_DOWNLOAD=true

# OpenCode v2 ships on npm as the scoped package @opencode/cli (the legacy
# opencode-ai package remains v1-only and silently ignores the v2 `plugins`
# key — see LEARNINGS/decisions/goal-plugin-v2-readoption.md, Docker note).
# The old global TS toolchain packages are deliberately absent: the v2 binary
# runs TS plugins natively (Bun-embedded) — nothing in this image invokes them.
RUN npm install -g "@opencode/cli@${OPENCODE_VERSION}"

RUN useradd -m -d /home/opencode -s /bin/bash opencode

# v2.0: build context is repo root. Copy app + content + the installer assets
# (installer/: model resolver + tier registry) and the deploy tooling (deploy/:
# merge-packs + packs).
ARG OPENCODE_PROVIDER=""
ARG OPENCODE_PACKS=""
COPY opencode_app/ /app/
# Content lives at the repo root (skills/, agents/, plugins/) and lands in the
# runtime-discovery location /app/.opencode/.
COPY skills/ /app/.opencode/skills/
COPY agents/ /app/.opencode/agents/
COPY plugins/ /app/.opencode/plugins/
COPY plugins/vibeguard.config.json /app/.opencode/vibeguard.config.json
COPY installer/ /app/installer/
COPY deploy/ /app/deploy/

# Bake resolved models into the image at build time (default z.ai unless
# OPENCODE_PROVIDER build-arg swaps the provider preset). --inject-primary is
# Docker-only: the default primary is baked in so the web endpoint has a model
# to serve with. Local (setup.sh) deploys omit it so the user picks at runtime.
RUN node /app/installer/resolve-models.mjs \
        --agents-src /app/.opencode/agents \
        --agents-dest /app/.opencode/agents \
        --tiers /app/installer/agent-tiers.json \
        --default-map /app/installer/models.default.json \
        --provider-models /app/installer/provider-models.json \
        --presets /app/installer/provider-presets.json \
        --inject-primary \
        $([ -n "$OPENCODE_PROVIDER" ] && echo "--provider $OPENCODE_PROVIDER") \
        --config-dest /app/opencode.json \
        --state /tmp/.resolved-models.json \
    && rm -f /tmp/.resolved-models.json \
# Overlay fragments (#576) are composition SOURCES, not runtime agents — the
# resolver consumed them above; leaving them here would ship dead .md files
# into OpenCode's agent-discovery dir.
    && rm -rf /app/.opencode/agents/overlays

# Provider packs (#268): set mcp.servers.<server>.disabled:false + append
# permissions-array allow rules ({action:"<ns>*",resource:"*",effect:"allow"});
# named packs (comma-separated, e.g. --build-arg OPENCODE_PACKS=markitdown).
# Runs AFTER resolve-models so it merges into the resolved /app/opencode.json.
# Empty OPENCODE_PACKS is a true no-op (merge-packs.mjs exits 0, writes nothing).
RUN if [ -n "$OPENCODE_PACKS" ]; then \
        node /app/deploy/merge-packs.mjs \
            --config /app/opencode.json \
            --packs-dir /app/deploy/packs \
            --packs "$OPENCODE_PACKS" ; \
    else \
        echo "OPENCODE_PACKS empty — skipping provider-pack merge" ; \
    fi

# Inside the container, 127.0.0.1 is the container itself. Local LLM services
# live in sibling compose containers, so rewrite provider baseURLs to use Docker
# service names. Host-based deploys (setup.sh) keep 127.0.0.1 in the source file.
# NOTE: targets the v2 config shape (providers.<name>.settings.baseURL);
# OPENCODE_VERSION above pins the v2 binary via @opencode/cli (#387).
RUN python3 - <<'PYEOF'
import json
path = "/app/opencode.json"
with open(path) as f:
    cfg = json.load(f)
providers = cfg.get("providers", {})
patched = []
if "local-llm" in providers:
    providers["local-llm"].setdefault("settings", {})["baseURL"] = "http://llm-server:8080/v1"
    patched.append("local-llm")
if "vllm" in providers:
    providers["vllm"].setdefault("settings", {})["baseURL"] = "http://vllm-server:8000/v1"
    patched.append("vllm")
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
if patched:
    print("Patched baseURLs for Docker networking:", ", ".join(patched))
PYEOF

RUN chmod +x /app/docker-entrypoint.sh \
    && mkdir -p /home/opencode/.local/share/opencode \
    && mkdir -p /home/opencode/.local/share/opencode-goal-plugin \
    && mkdir -p /home/opencode/.cache \
    && mkdir -p /home/opencode/.npm \
    && chown -R opencode:opencode /app /home/opencode

USER opencode

WORKDIR /app

ENV OPENCODE_SERVER_PORT=4096 \
    OPENCODE_SERVER_HOST=0.0.0.0

EXPOSE 4096

# v2 requires HTTP auth on every route (auto-generates a random password when
# OPENCODE_SERVER_PASSWORD is unset). docker-entrypoint.sh materializes the
# effective password at ${AUTH_DIR}/server-password so in-container healthchecks
# can authenticate. Liveness only — the compose file additionally asserts goal
# plugin presence.
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -sf -u "opencode:$(cat /home/opencode/.local/share/opencode/server-password 2>/dev/null)" \
        "http://localhost:${OPENCODE_SERVER_PORT}/api/health" || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]
