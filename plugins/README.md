# plugins/

OpenCode runtime plugins for this configurator. Glob-discovered by the OpenCode
plugin loader — no registration needed.

## Naming convention (#456)

| Prefix | Meaning | Deployed to OpenCode? |
|--------|---------|----------------------|
| `opencode-*.ts` | OpenCode runtime plugin (v2 `{ id, setup }` local port) | Yes — `deploy_plugins()` copies them to `~/.config/opencode/plugins/`; the Docker image `COPY`s the whole dir |
| `kimi-*` | Reserved: future Kimi Code plugin ports | **Never** auto-deployed to OpenCode |
| `kilo-*` | Reserved: future Kilo Code plugin ports | **Never** auto-deployed to OpenCode |

Rules:

1. **Every OpenCode runtime plugin file starts with `opencode-`.** The loader
   glob-discovers every `*.ts` in this directory, so the prefix is what keeps
   foreign-runtime plugins out of OpenCode's load path once they exist.
2. **Plugin `id` fields are stable** and independent of filenames — they appear
   in logs and debug greps; do not rename them when renaming files.
3. **`vibeguard.config.json` stays put.** The plugin resolves it via a search
   path (<project>/.opencode/ → deployed copies); renaming it breaks the
   Docker, setup.sh, and setup.ps1 legs at once.
4. **Before the first `kimi-*`/`kilo-*` plugin lands**, restrict
   `deploy_plugins()` (deploy/setup.sh) to `opencode-*.ts` + the `ponytail/`
   vendored dir — deferred from #456 by decision (no foreign plugin exists yet;
   no dead gating ships today).
5. Historical records (`LEARNINGS/`, `PLANS/`, `research/`) keep old paths —
   they are never rewritten.

MIT attributions for vendored code: see [ATTRIBUTION.md](ATTRIBUTION.md).
