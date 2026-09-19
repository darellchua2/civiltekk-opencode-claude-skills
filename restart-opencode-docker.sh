#!/usr/bin/env bash
#
# restart-opencode-docker.sh
# Purpose: Pull the latest 'main' branch of opencode-config-template and redeploy
#          the Docker-hosted OpenCode web service (docker compose up -d --build).
#
# Branch:  Deploys the 'main' branch — changes MUST be merged to main first.
#
# Health checks performed after redeploy:
#   1. Container health: docker inspect .State.Health.Status == healthy
#      (the image HEALTHCHECK authenticates with the entrypoint-materialized
#      password; the compose healthcheck additionally asserts goal-plugin
#      presence via /api/command)
#   2. Public endpoint:  GET https://opencode-ha.civiltekk.com -> expects 200/101
# On failure, recent container logs are printed.
#
set -euo pipefail

# Self-locating: works on any host that clones the repo, no hardcoded path.
cd "$(dirname "$(readlink -f "$0")")"

# Stash BEFORE checkout so a dirty feature branch can't abort the flow, and
# remember whether a stash exists so the pop below can fail loud.
STASHED=0
if [ -n "$(git status --porcelain)" ]; then
  git stash -q && STASHED=1
fi

git checkout main
git pull --ff-only

if [ "$STASHED" -eq 1 ]; then
  if ! git stash pop; then
    echo "ERROR: stash pop conflict — stashed changes are intact (git stash list)."
    echo "Resolve manually before redeploying; refusing to build from a conflicted tree."
    exit 1
  fi
fi

docker compose up -d --build

echo "Waiting for opencode to become healthy (compose start_period is 60s)..."
STATUS="starting"
for _ in $(seq 1 30); do
  STATUS=$(docker inspect --format '{{.State.Health.Status}}' opencode 2>/dev/null || echo "missing")
  if [ "$STATUS" = "healthy" ]; then
    break
  fi
  if [ "$STATUS" = "unhealthy" ] || [ "$STATUS" = "missing" ]; then
    echo "ERROR: container status '$STATUS' — recent logs:"
    docker logs opencode --tail 20 2>&1 || true
    exit 1
  fi
  sleep 5
done

if [ "$STATUS" != "healthy" ]; then
  echo "ERROR: container not healthy after 150s (status: $STATUS) — recent logs:"
  docker logs opencode --tail 20 2>&1 || true
  exit 1
fi

echo "OpenCode container is healthy."

echo "Checking opencode-ha.civiltekk.com..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://opencode-ha.civiltekk.com)
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 101 ]; then
  echo "opencode-ha.civiltekk.com is reachable (HTTP $HTTP_CODE)"
else
  echo "Warning: opencode-ha.civiltekk.com returned HTTP $HTTP_CODE"
fi
