# PS 5.1-targeting audits must not whitelist PSCore-only automatics

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #465

## Symptom

The static undefined-variable audit for `deploy/setup.ps1` (which declares
"Requires PowerShell 5.1+", setup.ps1:27) whitelisted
`$IsWindows`/`$IsLinux`/`$IsMacOS` in its automatic-variables set. Those exist
only in PowerShell Core — under Windows PowerShell 5.1 + `Set-StrictMode
-Version Latest` a future `if ($IsWindows)` guard would crash every stock
Windows invocation while the class-level audit stayed green.

## Root cause

The automatics list was copied from PSCore documentation without filtering by
the script's declared minimum runtime version. Whitelisting a name in an
undefined-variable audit is exactly equivalent to declaring the variable
always-defined — for a runtime the script doesn't support.

## Rule

Audit whitelists (automatic vars, globals) must be filtered against the
minimum runtime the target declares, not the newest. For setup.ps1 (5.1+):
no `$Is*` OS automatics, no PSCore-only builtins. If a future edit wants them,
the correct move is a runtime guard (`$PSVersionTable`), which the audit sees
as ordinary assigned code.
