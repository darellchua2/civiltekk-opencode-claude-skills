# Shipped command templates need mode-relative paths

- **Category**: solutions
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-26
- **Summary**: Globally-shipped command templates must not hardcode one deploy mode's absolute path — `/review-inline` pinned `~/.config/opencode/agents/` (setup.sh:92 CLI layout) while the Docker image stages agents at `/app/.opencode/agents` (Dockerfile:80, :99), so the in-container arm could not load its checklist (#582 review Major 3). **Rule:** a shipped template that reads a deployed file names the path PER DEPLOY MODE (CLI: `~/.config/opencode/agents/…`; Docker: `/app/.opencode/agents/…`) and carries an explicit unavailable-and-stop branch instead of improvising.
