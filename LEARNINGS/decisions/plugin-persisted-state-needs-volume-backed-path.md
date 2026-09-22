# Decision: plugin-persisted state needs a volume-backed path

Plugin state that must survive restarts goes under
`~/.local/share/opencode/`, not `~/.config/opencode/`.

Docker compose mounts only `opencode-data:/home/opencode/.local/share/opencode`
(+ named volumes); anything under `~/.config/opencode/` or `/app/` dies on
container recreation. Precedent: the goal plugin got a dedicated volume for
exactly this class of state (#387).

**Rule:** any PLAN adding plugin-persisted config must pin the path (or
record a docker env-var-only limitation note) — naming the docker consumer
in the Dependency & Consumer Map without an owning step is the
`plan-consumer-map-row-without-step` anti-pattern. Applied in PLAN-533
step 1.4: `~/.local/share/opencode/ponytail-config.json`, no compose change.

- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-22
