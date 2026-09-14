# Migration Guide: v1.x → v2.0 (Model Resolution System)

v2.0 is a **major breaking change**. Agent models are no longer hardcoded per
agent file — they are resolved at deploy time from a tier registry, so you can
switch providers (Z.AI / Anthropic / OpenAI / OpenRouter / local llama.cpp / vLLM)
without editing every agent file. This guide covers what changed, the automatic
migration, and how to revert.

---

## TL;DR

- Re-run `./deploy/setup.sh` (or `setup.ps1`). Existing installs are detected
  and migrated automatically — your customizations are preserved.
- To switch provider: `./deploy/setup.sh --provider anthropic` (interactive:
  `./deploy/setup.sh` and answer the provider prompt).
- To re-resolve models only: `./deploy/setup.sh --models-only`.
- **Behavior change (#333): deploys now default to the `lean` skill profile** —
  the primary session sees 45 primary-visible skills instead of 105 (~5.4k
  tokens less startup context at ~90 tokens/description). Opt back in with `--skill-profile full`
  (PowerShell: `-SkillProfile full`). Subagents are unaffected under either
  profile; re-running setup applies the profile to your deployed config.
- **Behavior change (#333): auto-start MCP servers reduced 6 → 2** —
  `codegraph` and `zai-web-reader` stay on; `atlassian` is now
  opt-in (project config or global flip). `zai-vision-mcp-server` and
  `zai-zread` were later **removed entirely** — native-multimodal vision
  agents + `gh`/`webfetch` cover their use cases. The `mermaid` MCP server
  and `zai-web-search-prime` were also removed (diagrams ship as inline
  fenced code blocks rendered client-side; built-in `webfetch` covers
  search-free reading). The 4 `autodesk-*` servers were also removed from
  the base config — the `autodesk` provider pack now carries their full
  definitions (`--enable-pack autodesk`, needs `AUTODESK_API_KEY`).
  Enable per-project by
  adding `<repo>/opencode.json` with `{"mcp":{"servers":{"atlassian":{"disabled":false}}}}`
  (project wins over global; `opencode-repo-setup-skill` automates this), or
  set `mcp.servers.<key>.disabled: false` in your global config to restore
  the old behavior.

---

## What changed

| | v1.x | v2.0 |
|---|---|---|
| Where the model lives | Hardcoded `model:` in each agent `.md` | Resolved from a tier registry at deploy time |
| Provider | Locked to Z.AI | Provider-agnostic (presets + overrides) |
| Source agent files | Contain concrete model IDs | 100% model/tier-free |
| Customization | Hand-edit each `.md` (lost on redeploy) | `models.json` (tier map) + `agent-overrides.json` (per-agent) |

### New concepts

- **4 tiers**: `reasoning`, `fast`, `docs`, `vision`. Each agent is categorized
  in `deploy/agent-tiers.json`.
- **Resolver** (`deploy/resolve-models.mjs`): injects concrete `model:` into the
  *deployed* agent files at deploy time + patches `opencode.json`.
- **Override files** (resolution precedence, highest first):
  1. `<project>/.opencode/agent-overrides.json` (per-agent, project-local)
  2. `~/.config/opencode/agent-overrides.json` (per-agent, global)
  3. `<project>/.opencode/models.json` (tier map, project-local)
  4. `~/.config/opencode/models.json` (tier map, global)
  5. `deploy/models.default.json` (Z.AI defaults)

> **Default tier models:** `reasoning` → `zai-coding-plan/glm-5.3`. **Image analysis (#283)**
> is not a vision tier — `image-analyzer-subagent`/`error-resolver-subagent` run on `docs`
> (`glm-4.7`) and obtain image content via `zai-vision-analysis-skill` (free `glm-4.6v-flash`
> through a direct Z.AI API call, since models.dev doesn't list it). The `vision` tier
> (`zai/glm-4.6v`) is opt-in paid only. The resolver also runs an **exposed-model guard** at
> deploy (`--provider-models deploy/provider-models.json`, aligned to models.dev) that fails
> fast if a tier/source-config pin references a model its provider doesn't serve.

---

## Automatic migration (on first v2.0 setup)

When you run `./deploy/setup.sh` on an existing v1.x install, the setup script:

1. **Detects** the old install via `~/.config/opencode/.config-version` (absent
   or `< 2.0`) and warns that this is a major upgrade.
2. **Backs up** your existing `~/.config/opencode/agents/` and `config.json` to
   `~/.opencode-backup-<timestamp>/`.
3. **Lifts** any agent whose current model is *not* a recognized Z.AI default
   into `~/.config/opencode/agent-overrides.json` — so your hand-tuned models
   survive as first-class managed overrides (never silently dropped).
4. **Re-resolves** all agents from the tier registry.
5. Writes `.config-version` = `2.0`.

This is **idempotent** — re-running on an already-v2 install is a no-op.

Run it explicitly (migration + resolution only):

```bash
./deploy/setup.sh --migrate        # interactive
./deploy/setup.sh --migrate -y     # non-interactive
```

Preview without changing anything:

```bash
./deploy/setup.sh --migrate --dry-run
```

---

## Choosing a provider

**Interactive** (arrow-key TUI):

```bash
./deploy/setup.sh            # answer "Choose a model provider?" → Y
```

**Non-interactive** (writes `~/.config/opencode/models.json`):

```bash
./deploy/setup.sh --provider anthropic
./deploy/setup.sh --provider openai
./deploy/setup.sh --provider openrouter
./deploy/setup.sh --provider zai          # default
```

Re-resolve after editing override files by hand:

```bash
./deploy/setup.sh --models-only
```

### Pinning a single agent

Edit `~/.config/opencode/agent-overrides.json`:

```json
{
  "code-review-subagent": { "model": "anthropic/claude-opus-4-8" }
}
```

Then `./deploy/setup.sh --models-only`.

### Mixing providers per category

Each of the 5 categories — `primary`, `reasoning`, `fast`, `docs`, `vision` — can
use a **different provider/model**. Pick interactively (recommended):

```bash
./deploy/setup.sh --mix          # per-category editor (base: Z.AI)
# or during interactive setup, choose option 2: "Mix providers per category"
```

This opens a per-category menu where, for each category, you pick any provider's
model (or type a custom `provider/model-id`). Example: keep Z.AI for everything
except `vision`, which you set to OpenAI.

The result is just a mixed `~/.config/opencode/models.json` you can also edit by
hand:

```json
{
  "primary": "zai-coding-plan/glm-5.3",
  "tiers": {
    "reasoning": "zai-coding-plan/glm-5.3",
    "fast": "zai-coding-plan/glm-5.3-flash",
    "docs": "zai-coding-plan/glm-4.7",
    "vision": "openai/gpt-5"
  }
}
```

Then `./deploy/setup.sh --models-only`.

> **Auth requirement:** every provider you reference must be authenticated in
> OpenCode (`opencode auth login`, or entries in `auth.json`). Z.AI is the
> default; using Anthropic/OpenAI/etc. requires authenticating that provider or
> the corresponding agents will fail at runtime (deploy still succeeds — the
> resolver only substitutes model strings; it does not validate reachability).
>
> **`--provider` vs `--mix`:** `--provider <X>` forces a *single* provider across
> all categories and overrides any hand-mixed `models.json`. To use a mixed map,
> resolve **without** `--provider` (mixing is stored in `models.json`).

### Personal config: small_model + vision fallback (GIT-357)

Two settings are deliberately **not shipped** — add them to
`~/.config/opencode/opencode.json` after deploy if you want them:

**1. `small_model`** — the resolver has no small_model support (local deploys omit
top-level model keys so you pick the primary at runtime). For cheap title/utility
generation on the GLM Coding Plan:

```json
{ "small_model": "zai-coding-plan/glm-5.3-flash" }
```

**2. Vision fallback** — the shipped vision tier is
`zai-coding-plan/glm-5.3-flash` (native models.dev catalog entry with
`attachment: true`; docs-verified multimodal). If the plan endpoint ever rejects
image parts, repoint the vision tier at the **pay-as-you-go** model via
`~/.config/opencode/models.json` instead of editing provider config:

```json
{ "tiers": { "vision": "zai/glm-5.3-flash" } }
```

Then `./deploy/setup.sh --models-only`.

---

## Context pruning (DCP) → v2 checkpoint compaction

In OpenCode v1, the Dynamic Context Pruning (DCP) plugin and legacy `compaction.prune` / `tail_turns` configurations mutated chat history continuously to trim token counts. In v2, this pattern is completely replaced by episodic checkpoint-based compaction.

### Workflow comparison

| | v1 DCP / `prune` | v2 checkpoint compaction |
|---|---|---|
| **When** | Every model request, continuously | Episodic — preflight check before each model call fires at `estimated tokens >= min(input limit − buffer, context limit − max(output reserve, buffer))`, plus one-shot overflow recovery |
| **What** | Old tool outputs deleted or abbreviated in place | Older context replaced by structured summary (`## Objective` / `## Next Move`) + newest `keep.tokens` verbatim; retained-tail tool outputs capped at 2,000 characters |
| **Visible** | Silent mutation | Checkpoint message in transcript; raw session history remains stored |
| **Info recovery** | None — pruned data permanently lost | Summary carries key decisions and state forward; subsequent compactions incrementally update it |

### Why v2 dropped prune and tail_turns

Per the v2 documentation: *"V2 has no native `tail_turns` or `prune` field; both legacy fields are ignored with a warning... V2 uses `compaction.keep.tokens` and checkpoint-based compaction instead."*

The shift resolves several architectural failure modes:
1. **Information relocation over deletion:** Pruning silently wipes earlier outputs, forcing models to repeat verified work. Summaries relocate state while discarding verbosity.
2. **Prompt-cache prefix preservation:** Continuous in-place mutation between turns breaks provider prompt-cache prefixes, incurring full input token pricing on every step. *(Note: Prompt cache invalidation reasoning is an inference from provider caching mechanics rather than an explicit claim in the OpenCode documentation).*
3. **Tool-pair integrity:** Selectively deleting or truncating tool outputs risks orphaning tool calls, resulting in upstream provider API protocol errors.
4. **Auditability and composability:** Transcripts retain honest records of what occurred, seamlessly composing with provider-native compaction features (e.g. OpenAI Responses checkpoints).

### Native knob mapping (each DCP responsibility → native setting)

| DCP / v1 Mechanism | OpenCode v2 Native Replacement | Defaults & Notes |
|---|---|---|
| History shrinking | `compaction.auto`, `compaction.keep.tokens`, `compaction.buffer` | Enabled by default (`auto: true`); retains latest 15,000 tokens (`keep.tokens: 15000`) with a 20,000 token trigger buffer (`buffer: 20000`). |
| Oversized tool outputs | Tail truncation + `tool_output.max_lines` / `max_bytes` | Retained-tail tool outputs capped at 2,000 chars during compaction; global limits default to 2,000 lines / 51,200 bytes. |
| Fixed token overhead | Skill and MCP allowlists | Deployed via `lean` skill profile (#333), saving ~5.4k tokens in initial system context. |
| Auto-continuation loop | Native checkpoint rebuild | Successful checkpoint automatically rebuilds the pending step without burning additional agent steps. |

### Token-reduction levers (ranked)

1. **Fixed overhead reduction (highest impact):** Adopt the `lean` skill profile and keep unused MCP servers disabled.
2. **Compaction tuning (moderate impact):** Adjust `compaction.keep.tokens` and `compaction.buffer` in your configuration based on model window size.
3. **Plugin ports (NOT recommended):** Do not attempt to port DCP as a v2 `session.hook("context")` plugin. V1 plugins do not execute on v2, mid-history mutation breaks prompt caching, and the native checkpoint engine provides superior stability.

### Verification and inspection

- Run `opencode stats` to inspect per-session token usage, token counts, and cost reports.
- To temporarily disable automatic compaction for debugging:
  ```bash
  OPENCODE_DISABLE_AUTOCOMPACT=1 opencode
  ```

### Sources and reference documentation
- <https://opencode.ai/v2/docs/compaction>
- <https://opencode.ai/v2/docs/config>
- <https://opencode.ai/v2/docs/build/plugins/migrate-v1>
- <https://opencode.ai/v2/docs/migrate-v1>

---

## Docker

Models are resolved at **build time**. To build with a non-default provider:

```bash
docker compose build --build-arg OPENCODE_PROVIDER=anthropic
```

(Defaults to Z.AI if the build-arg is omitted.)

### Provider Packs (build-time MCP toggle, #268)

v2.0 also adds **provider packs** — build-time toggles that enable groups of opt-in MCP servers (Autodesk, `markitdown`, `next-devtools`) in one shot. The merge runs after model resolution and only sets `mcp.servers.<name>.disabled: false` and appends `permissions`-array allow rules (`{ "action": "<ns>*", "resource": "*", "effect": "allow" }`); it never disables an already-enabled server.

```bash
# Enable one or more packs at build time
docker compose build --build-arg OPENCODE_PACKS=autodesk,markitdown

# User-space equivalent
./deploy/setup.sh --enable-pack autodesk,markitdown
```

No migration impact — packs default to OFF, so existing builds are unchanged unless the build-arg is set. See root `README.md` § Provider Packs for the full pack list.

---

## Reverting to v1.x

If you need to stay on v1.x:

1. Restore your backed-up agents + config:
   ```bash
   cp -r ~/.opencode-backup-<timestamp>/agents-backup/* ~/.config/opencode/agents/
   cp ~/.opencode-backup-<timestamp>/config.json ~/.config/opencode/config.json
   ```
2. Check out a pre-v2.0 tag of this repo.

Backups are retained per `--keep-backups` (default 5 most recent).

---

## Troubleshooting

- **`Node.js is required to resolve agent models`** — install Node.js v20+ first;
  the resolver is a Node script.
- **An agent got the wrong model** — check its tier in
  `deploy/agent-tiers.json`, then check `~/.config/opencode/models.json` (tier
  map) and `agent-overrides.json` (per-agent pin). Run `--models-only --dry-run`
  to preview the resolution table.
- **My custom model disappeared** — it should have been lifted into
  `agent-overrides.json` during migration. Check there, or restore from backup.

---

See `PLANS/PLAN-BT-74.md` for the full design and `deploy/provider-presets.json`
for the available provider model IDs.
