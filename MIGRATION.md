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
  in `installer/agent-tiers.json`.
- **Resolver** (`installer/resolve-models.mjs`): injects concrete `model:` into the
  *deployed* agent files at deploy time + patches `opencode.json`.
- **Override files** (resolution precedence, highest first):
  1. `<project>/.opencode/agent-overrides.json` (per-agent, project-local)
  2. `~/.config/opencode/agent-overrides.json` (per-agent, global)
  3. `<project>/.opencode/models.json` (tier map, project-local)
  4. `~/.config/opencode/models.json` (tier map, global)
  5. `installer/models.default.json` (Z.AI defaults)

> **Default tier models:** `reasoning` → `zai-coding-plan/glm-5.3`. **Image analysis (#283)**
> is not a vision tier — `image-analyzer-subagent`/`error-resolver-subagent` run on `docs`
> (`glm-4.7`) and obtain image content via `zai-vision-analysis-skill` (free `glm-4.6v-flash`
> through a direct Z.AI API call, since models.dev doesn't list it). The `vision` tier
> (`zai/glm-4.6v`) is opt-in paid only. The resolver also runs an **exposed-model guard** at
> deploy (`--provider-models installer/provider-models.json`, aligned to models.dev) that fails
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

## Context pruning (DCP) → v2 checkpoint compaction (#385)

**Verified against opencode.ai v2 docs 2026-09-14.** v1's DCP plugin (dynamic
context pruning) and the `compaction.prune` / `compaction.tail_turns` config
fields are gone in v2 — v1 plugin implementations do not load at all, and both
legacy fields are ignored with a warning. Native checkpoint compaction
replaces them.

| | v1 DCP / `prune` | v2 checkpoint compaction |
|---|---|---|
| When | Every model request, continuously | Episodic — preflight check before each model call, plus one-shot overflow recovery |
| What | Old tool outputs deleted/abbreviated in place | Older context replaced by a structured summary (`## Objective` / `## Next Move`) + newest `keep.tokens` retained; tool outputs in the tail shortened to 2,000 chars, never dropped |
| Visible | Silent mutation | Checkpoint message in the transcript; earlier messages stay stored |
| Info recovery | None — pruned data is gone | Summary carries decisions/state forward; later compactions update it |

The preflight check fires at:

```text
estimated tokens >= min(input limit - buffer, context limit - max(output reserve, buffer))
```

### Why v2 dropped pruning

These reasons are repo analysis of the documented v2 behavior, not quoted
opencode rationale.

1. **Pruning deletes information; summaries relocate it.** A pruned test-run
   output is forgotten — the model re-runs verified work. A checkpoint summary
   says "tests pass after X fix."
2. **Per-request mutation invalidates provider prompt-cache prefixes** every
   turn → full input price repeatedly. Checkpoints change the prefix rarely,
   so cache hits stay high between them. (Cache mechanics are inference from
   provider pricing behavior, not an opencode-docs statement.)
3. **Tool-pair integrity.** Deleting a tool output risks orphaning its
   `tool_call` (an API error on OpenAI/Anthropic). Token-budget retention
   never drops a message — tail content may be capped, never removed.
4. **Composability + auditability.** v2 can delegate to provider-native
   compaction (e.g. OpenAI Responses checkpoints), which a local prune layer
   cannot compose with; checkpoints are visible records, not silent rewrites.

### Native replacement mapping

| DCP-era job | v2 native knob |
|---|---|
| History shrinking | `compaction.auto` (default on) + `keep.tokens` (default 15000) + `buffer` (default 20000) |
| Oversized tool results | 2,000-char cap in the retained tail; globally via `tool_output.max_lines` / `max_bytes` (defaults 2000 / 51200) |
| Fixed overhead — unused tools/skills riding every request | Skill/MCP permission allowlists (the `lean` skill profile already ships this) |
| v1 `experimental.compaction.autocontinue` loop keep-alive | Native: a successful checkpoint rebuilds the same pending model step without spending another agent step |

### Token-reduction levers, ranked

1. **Trim fixed overhead** — every enabled MCP server's tool schemas ride on
   every request; disabling unused servers is the biggest permanent win.
2. **Tune compaction** — lower `keep.tokens` (8-12k) and raise `buffer` (~30k)
   to fire earlier and keep the tail small. Over-tightening costs extra
   summarization calls and re-reads of forgotten files.
3. **DCP-style plugin port** (`session.hook("context")` eliding old tool
   outputs) — **not recommended**: it re-accepts cache invalidation for the
   weakest lever. (The cache claim is inference from provider prompt-caching
   mechanics — cache reads bill at a fraction of input price — not an
   opencode-docs statement.)

Keep `warming` off (the default) — periodic keep-alive requests spend
tokens by design.

### Verify

- `"compaction": { "auto": false }` — the documented kill switch for
  automatic compaction (manual compaction still works).
- Measure before/after any tuning via your provider's usage dashboard
  instead of trusting intuition.

Sources: opencode.ai/v2/docs/compaction, /v2/docs/config,
/v2/docs/build/plugins/migrate-v1, /v2/docs/migrate-v1

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
  `installer/agent-tiers.json`, then check `~/.config/opencode/models.json` (tier
  map) and `agent-overrides.json` (per-agent pin). Run `--models-only --dry-run`
  to preview the resolution table.
- **My custom model disappeared** — it should have been lifted into
  `agent-overrides.json` during migration. Check there, or restore from backup.

---

See `PLANS/PLAN-BT-74.md` for the full design and `installer/provider-presets.json`
for the available provider model IDs.
