# Safety snapshot gated on a side-effect-created directory

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Evidence**: setup.sh:3290-3291 (`deploy_content` gates content-backup on `[ -d "$BACKUP_DIR" ]`), setup.sh:2457+2464 (`create_backup` only runs when the user confirms config overwrite; `--yes` auto-accepts default "n"), setup.ps1:2258 mirror.

BACKUP_DIR is created as a side effect of unrelated user choices (config-overwrite confirm, v1→v2 migration). A pre-clobber snapshot must `mkdir -p` its own target whenever there is content to snapshot — never depend on the backup dir already existing. In a `--yes` redeploy (the standard path) the gate skips the snapshot exactly when force-copy is about to overwrite local edits. Found in #379 review (feat/379).
