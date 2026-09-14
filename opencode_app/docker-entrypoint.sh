#!/bin/bash
set -e

PORT="${OPENCODE_SERVER_PORT:-4096}"
HOST="${OPENCODE_SERVER_HOST:-0.0.0.0}"

AUTH_DIR="/home/opencode/.local/share/opencode"
AUTH_FILE="${AUTH_DIR}/auth.json"
mkdir -p "${AUTH_DIR}"

# ── Server auth (v2) ─────────────────────────────────────────────────────────
# OpenCode v2 requires HTTP auth on EVERY route (healthchecks included) and
# auto-generates an unguessable password when none is set — one that in-container
# healthchecks could never learn. Materialize the effective password here: use
# OPENCODE_SERVER_PASSWORD from the environment if provided, otherwise generate
# one. The file lets healthchecks authenticate (docker healthcheck processes do
# not inherit this PID1's exports).
SERVER_PASSWORD_FILE="${AUTH_DIR}/server-password"
if [ -n "${OPENCODE_SERVER_PASSWORD}" ]; then
    printf '%s' "${OPENCODE_SERVER_PASSWORD}" > "${SERVER_PASSWORD_FILE}"
    chmod 600 "${SERVER_PASSWORD_FILE}"
    echo "Server auth: using OPENCODE_SERVER_PASSWORD from environment"
else
    GENERATED_PW="$(head -c 24 /dev/urandom | base64 | tr -d '=+/')"
    export OPENCODE_SERVER_PASSWORD="${GENERATED_PW}"
    printf '%s' "${GENERATED_PW}" > "${SERVER_PASSWORD_FILE}"
    chmod 600 "${SERVER_PASSWORD_FILE}"
    echo "Server auth: generated password (also at ${SERVER_PASSWORD_FILE}): ${GENERATED_PW}"
fi

# Ensure cache dir exists and is writable (defensive against volume mounts)
CACHE_DIR="/home/opencode/.cache"
mkdir -p "${CACHE_DIR}"
if [ -d "${CACHE_DIR}" ] && [ "$(stat -c '%U' "${CACHE_DIR}" 2>/dev/null)" = "root" ]; then
    echo "WARNING: ${CACHE_DIR} is owned by root; this may break opencode cache writes"
fi

python3 << PYEOF
import json, os

auth = {}

zai_key = os.environ.get("ZAI_API_KEY", "").strip()
if zai_key:
    auth["zai"] = {"type": "api", "key": zai_key}

gemini_key = os.environ.get("GEMINI_API_KEY", "").strip()
if gemini_key:
    auth["gemini"] = {"type": "api", "key": gemini_key}

auth_file = "${AUTH_FILE}"

if auth:
    with open(auth_file, "w") as f:
        json.dump(auth, f, indent=2)
    keys = ", ".join(auth.keys())
    print("Injected " + str(len(auth)) + " API key(s) into " + auth_file + ": " + keys)
else:
    print("WARNING: No API keys provided (ZAI_API_KEY, GEMINI_API_KEY)")
    print("OpenCode will start but LLM calls will fail without authentication")
PYEOF

# ── SSH key setup ───────────────────────────────────────────────────────────
if [ -d /tmp/ssh-host ] && [ "$(ls -A /tmp/ssh-host 2>/dev/null)" ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    cp -r /tmp/ssh-host/* ~/.ssh/ 2>/dev/null || true
    chmod 600 ~/.ssh/id_* 2>/dev/null || true
    chmod 600 ~/.ssh/config 2>/dev/null || true
    chmod 644 ~/.ssh/*.pub 2>/dev/null || true
    touch ~/.ssh/known_hosts
    chmod 644 ~/.ssh/known_hosts
    echo "SSH keys copied from host with correct permissions"
else
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/known_hosts
    echo "No SSH keys found at /tmp/ssh-host — skipping SSH setup"
fi

# Add github.com to known_hosts (prevents first-connect prompt)
if ! grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null; then
    ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts 2>/dev/null || true
    echo "Added github.com to known_hosts"
fi

# ── Git identity ────────────────────────────────────────────────────────────
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

if [ -n "${GIT_USER_NAME}" ]; then
    git config --global user.name "${GIT_USER_NAME}"
    echo "Set git user.name: ${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL}" ]; then
    git config --global user.email "${GIT_USER_EMAIL}"
    echo "Set git user.email: ${GIT_USER_EMAIL}"
fi

# ── Ponytail (scoped wrapper plugin) ──────────────────────────────────────────
# Default lazy-code intensity: lite | full | ultra | off (default: full).
# Read by the ponytail-scoped.mjs plugin at load time.
export PONYTAIL_DEFAULT_MODE="${PONYTAIL_DEFAULT_MODE:-full}"

# Regex of agent names that SKIP ruleset injection (read-only/research agents).
# Default excludes the 7 read-only/research agents. Override to add/remove.
export PONYTAIL_SUBAGENT_OFF="${PONYTAIL_SUBAGENT_OFF:-}"

# Optional per-agent mode overrides as JSON, e.g. {"build":"full","code-review-subagent":"lite"}
# Unset by default — PONYTAIL_DEFAULT_MODE governs all non-off-set agents.
export PONYTAIL_AGENT_MODE_MAP="${PONYTAIL_AGENT_MODE_MAP:-}"

echo "Ponytail: mode=${PONYTAIL_DEFAULT_MODE} off-set=$([ -n \"${PONYTAIL_SUBAGENT_OFF}\" ] && echo 'custom' || echo 'default')"

# ── Workspace ───────────────────────────────────────────────────────────────
# Tolerate absence of the /workspace bind mount (bare docker run): compose
# always mounts it; without the mount, root owns / and mkdir would fail.
mkdir -p /workspace 2>/dev/null || true
mkdir -p /workspace-extra 2>/dev/null || true

# ── Goal plugin presence assertion (#387) ────────────────────────────────────
# The v2 `plugins` key being silently ignored was the exact failure mode that
# kept /goal out of this endpoint (LEARNINGS: docker-v1-binary-ignores-v2-
# plugins-key). Poll /api/command until the goal commands appear — NOT merely
# until the server answers: /api/command serves 200 before the plugin's async
# npm fetch+register completes, so a first-success poll races and false-alarms.
# Greppable verdict keeps inertness loud; non-fatal so a deliberate plugin
# removal does not brick the endpoint (the compose healthcheck owns the
# ongoing assertion).
(
    PW="$(cat "${SERVER_PASSWORD_FILE}" 2>/dev/null)"
    BODY=""
    for _ in $(seq 1 30); do
        sleep 2
        BODY="$(curl -sf -u "opencode:${PW}" "http://localhost:${PORT}/api/command" 2>/dev/null)" || true
        echo "${BODY}" | grep -q '"goal' && break
    done
    if echo "${BODY}" | grep -q '"goal'; then
        echo "GOAL-PLUGIN: OK — goal commands registered (@prevalentware/opencode-goal-plugin active)"
    else
        echo "GOAL-PLUGIN: ABSENT — no goal commands in /api/command after 60s; the plugins key is inert (check binary version and opencode_app/opencode.json)" >&2
    fi
) &

echo "Starting OpenCode server on ${HOST}:${PORT}..."
exec opencode serve --port "${PORT}" --hostname "${HOST}"
