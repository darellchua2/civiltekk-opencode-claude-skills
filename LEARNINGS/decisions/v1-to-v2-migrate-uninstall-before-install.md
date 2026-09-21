# v1-to-v2 CLI migration must uninstall before install

- **Category**: decision
- **Confidence**: 0.85
- **Scope**: project
- **Evidence**: deploy/setup.sh `setup_opencode` + `update_opencode_cli` v1-detection branches run `npm uninstall -g opencode-ai` BEFORE `npm install -g @opencode/cli@latest` (migration prompts, default y); rationale pinned in tests/test_v2_cli_package.bats header + the uninstall-then-install assertion order (#499).

The v1 npm package `opencode-ai` (frozen 1.18.31) and the v2 scoped package `@opencode/cli` both provide the `opencode` bin; installing v2 over a package-managed v1 leaves the shared bin link shadowed or broken (npm owns bin links per package — uninstalling the stale one afterward can remove the link v2 needs). The official order (opencode.ai/v2 migrate-v1: "Remove a package-managed V1 installation before installing V2") is encoded in both migration branches. Any future install path that can encounter a v1 install must preserve uninstall-then-install; never a bare v2 install "over" v1, never uninstall-after.

A user who declines the migration stays on v1 — the deploy config's v2 `plugins` key is silently ignored there (#387 failure class), so the decline branch warns explicitly and `print_summary` labels 1.x installs `opencode-ai (v1)` instead of certifying them as `@opencode/cli`.
