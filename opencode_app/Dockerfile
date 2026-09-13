FROM node:24-bookworm-slim

LABEL org.opencontainers.image.title="opencode-config-template" \
      org.opencontainers.image.description="OpenCode standalone web endpoint - configurable agent/skill runner" \
      org.opencontainers.image.source="https://github.com/darellchua2/opencode-config-template"

ARG OPENCODE_VERSION=1.18.20

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        ca-certificates \
        curl \
        git \
        ripgrep \
        openssh-client \
        chromium \
        fonts-liberation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_DOWNLOAD=true

RUN npm install -g "opencode-ai@${OPENCODE_VERSION}" \
    typescript \
    ts-node

RUN python3 -m venv /opt/python-env
ENV PATH="/opt/python-env/bin:${PATH}"

RUN pip install --no-cache-dir \
    "openpyxl>=3.1.0" \
    "pandas>=3.0.0" \
    "pdfplumber>=0.11.0" \
    "requests>=2.32.0" \
    "numpy>=2.0.0" \
    "fastapi>=0.115.0"

RUN useradd -m -d /home/opencode -s /bin/bash opencode

# v2.0: build context is repo root. Copy app + the model-resolver assets (deploy/).
ARG OPENCODE_PROVIDER=""
ARG OPENCODE_PACKS=""
COPY opencode_app/ /app/
COPY deploy/ /app/deploy/

# Bake resolved models into the image at build time (default z.ai unless
# OPENCODE_PROVIDER build-arg swaps the provider preset). --inject-primary is
# Docker-only: the default primary is baked in so the web endpoint has a model
# to serve with. Local (setup.sh) deploys omit it so the user picks at runtime.
RUN node /app/deploy/resolve-models.mjs \
        --agents-src /app/.opencode/agents \
        --agents-dest /app/.opencode/agents \
        --tiers /app/deploy/agent-tiers.json \
        --default-map /app/deploy/models.default.json \
        --provider-models /app/deploy/provider-models.json \
        --presets /app/deploy/provider-presets.json \
        --inject-primary \
        $([ -n "$OPENCODE_PROVIDER" ] && echo "--provider $OPENCODE_PROVIDER") \
        --config-dest /app/opencode.json \
        --state /tmp/.resolved-models.json \
    && rm -f /tmp/.resolved-models.json

# Provider packs (#268): flip mcp.<server>.enabled + set root permission
# named packs (comma-separated, e.g. --build-arg OPENCODE_PACKS=autodesk);
# the permission allow pattern is "<ns>*": "allow" at the config root.
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
# NOTE: targets the v2 config shape (providers.<name>.settings.baseURL) —
# requires a v2 opencode binary; OPENCODE_VERSION above still pins v1 until a
# v2 npm release ships (tracked as the Docker follow-up on ticket #374).
RUN python3 - <<'PYEOF'
import json
path = "/app/opencode.json"
with open(path) as f:
    cfg = json.load(f)
providers = cfg.get("providers", {})
if "local-llm" in providers:
    providers["local-llm"].setdefault("settings", {})["baseURL"] = "http://llm-server:8080/v1"
if "vllm" in providers:
    providers["vllm"].setdefault("settings", {})["baseURL"] = "http://vllm-server:8000/v1"
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
print("Patched local-llm/vllm baseURLs for Docker networking")
PYEOF

RUN chmod +x /app/docker-entrypoint.sh \
    && mkdir -p /home/opencode/.local/share/opencode \
    && mkdir -p /home/opencode/.cache \
    && chown -R opencode:opencode /app /home/opencode

# PLAN-GIT-262: bake the privacy-hardened markitdown MCP launcher into the
# image. Uses /opt/python-env/bin/pip so the console-script lands in
# /opt/python-env/bin (already on PATH via ENV on line 33). Do NOT use uv -
# it is not installed in this image.
RUN /opt/python-env/bin/pip install --no-cache-dir /app/mcp-servers/markitdown-local-mcp

USER opencode

WORKDIR /app

ENV OPENCODE_SERVER_PORT=4096 \
    OPENCODE_SERVER_HOST=0.0.0.0

EXPOSE 4096

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:${OPENCODE_SERVER_PORT}/global/health || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]
