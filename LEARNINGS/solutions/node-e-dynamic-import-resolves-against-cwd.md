# node -e dynamic import() resolves relative specifiers against process cwd

- **Category**: solution
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-23
- **Ticket**: #537

## Symptom

A `node -e 'import("./installer/mod.mjs")'` one-liner inside `setup.sh` works
from the repo root and breaks with "Cannot find module" when the script runs
from anywhere else — and `setup.sh` legitimately runs from any cwd via the
`~/.local/bin/opencode-setup` PATH shim.

## Root cause

In `node -e` there is no script file, so relative import specifiers resolve
against `process.cwd()`, not the script's directory.

## Solution

Pass the absolute module path in as an argv slot (argv[1] is the first user
arg — see `node-e-argv-has-no-script-name-slot`) and import via
`pathToFileURL` for Windows-node robustness:

```js
const { pathToFileURL } = require("node:url");
import(pathToFileURL(process.argv[1]).href).then(…).catch(…)
```

`setup.sh` already computes an absolute `REPO_DIR` (symlink-aware) — hand
that down. Pin cwd-independence with a test run from a second directory
(`list_items_dump_lists_real_packs_and_plugins` runs once from the repo root
and once from `/tmp`).
