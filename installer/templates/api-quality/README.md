# API Authoring Quality Gate (opt-in template)

Deterministic enforcement for OpenAPI spec quality — the **hard net** behind the soft
prompt-level gate (#319: `api-design-skill` §Authoring Quality Gate + deploy `AGENTS.md`
routing). LLMs can drift past prompts; a pre-commit hook cannot be drifted past.

Filed as #320. Ships as a copy-adopt template — this repo is a configurator, not an app repo.

## Files

| File | Purpose |
|------|---------|
| `redocly.yaml` | Authoring-quality ruleset (copy to your repo root) |
| `api-quality-rules.mjs` | Custom rule: `example` required on POST/PUT request bodies |
| `pre-commit-redocly` | Plain git hook: lints staged `openapi.*` / `swagger.*` files |

## Adopt in your repo

1. Copy the ruleset + plugin to your repo root:

   ```bash
   curl -fsSL -o redocly.yaml https://raw.githubusercontent.com/darellchua2/opencode-config-template/main/installer/templates/api-quality/redocly.yaml
   curl -fsSL -o api-quality-rules.mjs https://raw.githubusercontent.com/darellchua2/opencode-config-template/main/installer/templates/api-quality/api-quality-rules.mjs
   ```

2. Install the hook (plain git — no framework dependency):

   ```bash
   curl -fsSL -o .git/hooks/pre-commit https://raw.githubusercontent.com/darellchua2/opencode-config-template/main/installer/templates/api-quality/pre-commit-redocly
   chmod +x .git/hooks/pre-commit
   ```

   Or with the [pre-commit framework](https://pre-commit.com/):

   ```yaml
   repos:
     - repo: local
       hooks:
         - id: redocly-lint
           name: redocly lint
           entry: npx -y @redocly/cli@2.53.3 lint --config redocly.yaml
           language: system
           files: '(^|/)(openapi\.(ya?ml|json)|swagger\.(ya?ml|json))$'
   ```

3. Smoke-test it: stage a spec with a missing `operationId` — the commit must fail;
   fix it — the commit must pass.

## Rules enforced

| Rule | Severity | Meaning |
|------|----------|---------|
| `operation-description` (builtin) | error | Every operation documents its behavior |
| `operation-operationId` (builtin) | error | Every operation has a stable `operationId` (client generation, contract diffs) |
| `api-quality/schema-description` (custom) | error | Every schema documents its shape — Redocly 2.x removed the builtin `schema-description`; this plugin restores it |
| `api-quality/operation-has-tags` (custom) | warn | Operations are tagged for grouping — v2 removed builtin `operation-tags` |
| `api-quality/request-body-example` (custom) | warn | POST/PUT request bodies carry `example`/`examples` — promote to `error` in `redocly.yaml` once specs comply |

`extends: [recommended]` adds Redocly's standard net on top (4xx responses, valid
examples, …).

The CLI version is **pinned** (`@redocly/cli@2.53.3`) so lint results are reproducible
and a registry push can never change your gate's behavior. Bump deliberately — the
plugin targets the 2.x plugin API (factory export, function rules, `key` = HTTP method
on Operation visitors).

## Code-generated specs

The hook lints staged files regardless of origin — lint the generator's output, not its
input. Missing descriptions on generated specs fail here; per-language docstring
enforcement is a separate concern (#320 out-of-scope note).
