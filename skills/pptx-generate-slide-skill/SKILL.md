---
name: pptx-generate-slide-skill
description: >-
  Fill a PowerPoint template with structured JSON via python-pptx Slide Master
  layouts. Not for presentations from scratch.
license: Apache-2.0
compatibility: opencode
category: Presentation
---

## What I do

I fill the PowerPoint template (`template.pptx`) with structured content using `ppt_builder.py`. I am the **only approved method** for generating presentations from structured data.

- Accept a JSON array (`slide_data_list`) and render it into a `.pptx` file
- Resolve Slide Master layouts **by name** (robust to layout reordering)
- Add slides from the template's Slide Master layouts, filling placeholders by type
- Embed **native charts** (editable, not images) and **native pictures**
- Resolve resource placeholders (`data_query`) into real assets before rendering
- **Validate** every deck against a JSON schema (with two-layer retry) before it reaches the engine
- Write speaker notes (in the user's prompt language) to each slide's Notes pane (Presenter View only)
- Handle missing placeholders gracefully with warnings (never crash)

## When to use me

Use this skill when:
- You have structured content (JSON array) and need a `.pptx` output
- You want to populate a Slide Master template with pre-defined layouts

Do NOT use for:
- Creating presentations from scratch
- OOXML editing or raw XML manipulation
- Thumbnail generation or visual analysis

## Template

The engine is **template-agnostic** (Capability A, issues #43/#44/#45): it accepts **any** `.pptx`, introspects it into a JSON contract, and fills it using that template's own layouts — matched by **placeholder-composition fingerprint**, not hardcoded names.

| File | Description |
|------|-------------|
| `template/default.pptx` | Slide Master template (repo root) — the **bundled default**, used when no `template_path` is given. |
| `template/default.config.json` | Optional layout-name pins (`<slide_type>_layout` for any of the 8 types). |
| `template/default.pptx.contract.json` | Auto-generated introspection contract (mtime-cached, gitignored). |

### User-supplied template (path pass-through)

To render from a user's own template, **pass its path as `template_path`** (or CLI `--template`) — do NOT overwrite the default. The engine introspects it automatically before every render. Omitting `template_path` uses `template/default.pptx`:

```bash
# default template (no path given)
python ppt_builder.py --output report.pptx --data slides.json

# user template (path pass-through, default untouched)
python ppt_builder.py --template /path/to/user.pptx --output report.pptx --data slides.json
```

**Severe template problems abort (US-4.7):** if the chosen template is corrupt / not a PPTX / has no slide master / has zero layouts / serves none of the 8 slide types, the engine raises `TemplateError` instead of silently producing a broken deck. Minor issues (missing fonts, no header/footer, small content area) stay non-fatal warnings.

### Template introspection + capability report

`template_introspector.py` produces the contract (slide size, theme, every layout's placeholders + fingerprint + content area). `servable_slide_types(contract)` reports which of the 8 slide types the template can serve — use it to constrain content to layouts the template actually provides:

```bash
python -c "
import sys, json; sys.path.insert(0,'scripts')
from ppt_builder import servable_slide_types, get_render_contract
print(json.dumps(servable_slide_types(get_render_contract('template/default.pptx')), indent=2))
"
```

### Layout resolution (fingerprint-first)

Layouts are resolved **by placeholder-composition fingerprint**, not by index. For each `slide_type` the engine has an ideal placeholder composition (a built-in constant); it matches that to the template layout whose composition fits best. **Layout names are only a tie-breaker / fallback.** Resolution precedence:

1. `default.config.json` pin (`<slide_type>_layout`) — explicit layout name, highest precedence.
2. **Fingerprint match** — composition-closest layout (the template-agnostic path).
3. Name-based fallback (`_LAYOUT_NAME_MAP`) — backward-compatible safety net.
4. Degradation — skip the slide + clear warning (never silent).

Among composition-compatible layouts, ranking is: name affinity → fewest surplus placeholders → largest `content_area_in2` → index. Without a contract the path is the original name-based matching (byte-for-byte backward compatible).

## Input Data Format

**Language: Multilingual (RELAXED).** Slide content (titles, body) and speaker notes MAY be in any language — match the user's prompt language. The orchestrator (`pptx-specialist-subagent`) enforces this relaxed policy: multilingual content is acceptable; do NOT force-translate non-English requests into English. Speaker notes MUST preserve the original user message verbatim and append a suggested transition.

```json
[
  {
    "slide_type": "title_slide",
    "title": "BETEKK 2026 Q1 Quarterly Review",
    "subtitle": "March 2026",
    "notes": "KEY MESSAGE: Open with energy — set the context in one line.\n\"Hold the slide for two seconds before you speak.\"\n\"Good [morning/afternoon], I'm [Name]. Welcome to our Q1 review — the short version is, we had a strong quarter.\"\nPause. Let it land.\n\"I'll take you through the numbers, then what's next.\"\nTRANSITION: \"Let's look at the numbers.\"\nCOACHING: Eye contact, confident. Do not read the slide."
  },
  {
    "slide_type": "content_slide",
    "title": "Key Business Metrics",
    "body": "**Revenue Growth** — 32% YoY increase\n**New Contracts** — 18 signed this quarter\n**Customer Satisfaction** — 96.5% approval rating",
    "notes": "KEY MESSAGE: Strong across every metric — revenue, pipeline, and satisfaction.\n\"Three numbers tell the story this quarter.\"\n\"Revenue is up thirty-two percent year on year — our fastest growth yet.\"\nPause. Let the number land.\n\"We signed eighteen new contracts, and customer satisfaction sits at ninety-six-point-five percent.\"\n\"Ask yourself: which of these would you lead with to your board?\"\nTRANSITION: \"Here is what actually drove these results.\"\nCOACHING: Matter-of-fact tone. Be ready for: \"Is the satisfaction score biased?\" — answer: independent survey, 200+ respondents."
  }
]
```

### Field Reference

| Field | Required | Slide Type | Description |
|-------|----------|------------|-------------|
| `slide_type` | Yes | All | One of: `title_slide`, `content_slide`, `section_header_slide`, `two_content_slide`, `comparison_slide`, `content_image_slide`, `chart_slide`, `closing_slide` |
| `title` | Yes | All | Main heading text |
| `subtitle` | No | `title_slide`, `closing_slide` | Subheading text. On `closing_slide`, omit this field — the `End` layout's built-in sign-off block shows by default. |
| `body` | No | `content_slide`, `content_image_slide` | Body content. `\n` = new paragraph. Format: `**Title** — Description` |
| `body_left` / `body_right` | No | `two_content_slide`, `comparison_slide` | Left/right column body (same body-text format) |
| `chart_type` | Yes | `chart_slide` | Chart type: `bar`, `bar_stacked`, `bar_horizontal`, `bar_horizontal_stacked`, `pie`, `pie_exploded`, `doughnut`, `line`, `line_markers` |
| `categories` | Yes | `chart_slide` | Array of category labels (X-axis or pie slice labels) |
| `series` | Yes | `chart_slide` | Array of `{name, values}` objects. Multiple series supported for bar/line. |
| `chart_options` | No | `chart_slide` | Styling options (see Chart Options below) |
| `image_path` | No | `content_image_slide` + any | Local file path of an image to embed as a **native, editable picture**. When set, the engine inserts it (#18). |
| `image_position` | No | any slide with `image_path` | Named placement preset: `full`, `half-left`, `half-right`, `below-title` (default). |
| `image_size` | No | any slide with `image_path` | `{"width": inches, "height": inches}` override of the preset box. |
| `data_query` | No | `chart_slide` | Resource placeholder — asks for real chart statistics; the resolver fills `categories`/`series` with sourced numbers. |
| `data_hint` | No | `chart_slide` | Optional expected shape for `data_query` (e.g. category/series names). |
| `notes` | Yes | All | Full presenter script (**~120–180 words**). Written to the slide's Notes pane (Presenter View only). `\n` = new paragraph. Must be **spoken dialogue** (quoted, speakable sentences tied to the slide's content), **interspersed stage directions**, a `TRANSITION` line, and `COACHING` with delivery + an anticipated Q&A — NOT bullet summaries. Cover/closing use `[Name]` / `[morning/afternoon]` placeholders. |
| `presenter_name` | No | `closing_slide` | Sign-off name. Omit on first generation — engine removes the placeholder. Set only when user picks "Add presenter sign-off" in Stage 5 refinement. |
| `presenter_email` | No | `closing_slide` | Sign-off email. Same lifecycle as `presenter_name`. |

### Body Text Parsing

Each line is parsed into a bold title run + description run:
- Split at first ` — `, ` - `, or `: `
- `**` markers stripped automatically
- No card slot limit — body is a single multi-paragraph block

## Chart Slides

The `chart_slide` type generates **native PowerPoint charts** (editable in PowerPoint, not images) using `python-pptx`'s `add_chart()` API. Charts use the `Blank` layout (which has a TITLE placeholder + free space for the chart graphic).

### Chart Type Reference

| `chart_type` | XL_CHART_TYPE | Description |
|---|---|---|
| `bar` | COLUMN_CLUSTERED | Vertical bars (default) |
| `bar_stacked` | COLUMN_STACKED | Stacked vertical bars |
| `bar_horizontal` | BAR_CLUSTERED | Horizontal bars |
| `bar_horizontal_stacked` | BAR_STACKED | Stacked horizontal bars |
| `pie` | PIE | Standard pie chart |
| `pie_exploded` | PIE_EXPLODED | Exploded pie chart |
| `doughnut` | DOUGHNUT | Doughnut chart |
| `line` | LINE | Simple line chart |
| `line_markers` | LINE_MARKERS | Line with data point markers (recommended) |

### Chart Options

All fields inside `chart_options` are optional with sensible defaults:

| Option | Type | Default | Description |
|---|---|---|---|
| `legend_position` | string | `"bottom"` | `"bottom"`, `"right"`, `"top"`, `"left"`, or `"none"` |
| `show_data_labels` | bool | `true` | Show value/percentage labels on chart |
| `value_format` | string | `"#,##0.0"` | Number format for bar/line data labels |
| `y_axis_format` | string | `"#,##0.0"` | Number format for Y-axis tick labels |
| `y_axis_min` | float | auto | Y-axis minimum scale |
| `y_axis_max` | float | auto | Y-axis maximum scale |
| `y_axis_major_unit` | float | auto | Y-axis major gridline interval |
| `y_axis_title` | string | `""` | Y-axis title text |
| `x_axis_title` | string | `""` | X-axis title text |

### Theme Styling

Charts automatically use the template's theme:
- **Colors**: 8-color palette extracted from theme accent colors (`accent1`-`accent6` + `dk2` + `accent3`)
- **Fonts**: All chart text uses `Calibri` (theme minor font)
- **Gridlines**: Major gridlines in `#E7E6E6` (theme `lt2`), 0.75pt
- **Axis text**: `#44546A` (theme `dk2`)

### Example: Bar Chart (single series)

```json
{
  "slide_type": "chart_slide",
  "title": "Global Construction Tech Market (USD Billion)",
  "chart_type": "bar",
  "categories": ["2020", "2021", "2022", "2023", "2024", "2025", "2026"],
  "series": [
    {"name": "Market Size", "values": [8.5, 11.2, 14.8, 19.5, 25.1, 31.7, 39.4]}
  ],
  "chart_options": {
    "legend_position": "bottom",
    "show_data_labels": true,
    "y_axis_min": 0,
    "y_axis_max": 45
  },
  "notes": "KEY MESSAGE: Market growing from 8.5B to 39.4B by 2026."
}
```

### Example: Pie Chart

```json
{
  "slide_type": "chart_slide",
  "title": "Technology Adoption Rate",
  "chart_type": "pie",
  "categories": ["BIM", "IoT", "Drones", "AI & ML", "Robotics", "Cloud"],
  "series": [
    {"name": "Adoption %", "values": [68, 45, 52, 28, 15, 72]}
  ],
  "chart_options": {
    "legend_position": "right"
  },
  "notes": "KEY MESSAGE: Cloud and BIM lead adoption at 72% and 68%."
}
```

### Example: Line Chart (multi-series)

```json
{
  "slide_type": "chart_slide",
  "title": "Project Performance Improvement (%)",
  "chart_type": "line_markers",
  "categories": ["2019", "2020", "2021", "2022", "2023", "2024", "2025"],
  "series": [
    {"name": "Cost Savings",       "values": [5, 8, 12, 16, 20, 25, 30]},
    {"name": "Schedule Reduction", "values": [3, 6, 10, 14, 19, 24, 28]},
    {"name": "Safety Improvement", "values": [2, 4,  8, 12, 18, 22, 27]}
  ],
  "chart_options": {
    "legend_position": "bottom",
    "y_axis_min": 0,
    "y_axis_max": 35
  },
  "notes": "KEY MESSAGE: All three metrics show consistent improvement."
}
```

## Image Slides

Any slide carrying an `image_path` embeds a **native, editable PowerPoint picture** (#18). If the layout has a PICTURE placeholder (e.g. `content_image_slide` → `Picture with Caption`), the picture fills it; otherwise it is placed in the free space using a named preset. Images are **embedded** (not linked), so the PPTX is self-contained.

### Placement presets (`image_position`)

| Preset | Region |
|--------|--------|
| `full` | Below title, full width (~11.5" × 4.5") |
| `below-title` | Same as `full` (default) |
| `half-left` | Left half (~5.75" × 4.5") |
| `half-right` | Right half (~5.75" × 4.5") |

Optional `image_size`: `{"width": 6, "height": 3}` (inches) overrides the preset box.

### Example: image slide

```json
{
  "slide_type": "content_image_slide",
  "title": "Drone Surveying in Action",
  "body": "**Aerial scans** - cut survey time by 60%",
  "image_path": "output/site_photo.png",
  "image_position": "full",
  "notes": "KEY MESSAGE: ..."
}
```

## Resource Resolution Pipeline

Instead of fabricating asset URLs or chart numbers, emit **placeholders**; an independent resolver pass replaces them with concrete assets **before** rendering. The agent never touches real URLs — it only describes what it wants.

| Placeholder | Resolved to | Provider |
|-------------|-------------|----------|
| `data_query` (+ `data_hint`) | populated `categories`/`series` | Agent `webfetch` pre-flight (resolver does NOT network); citation added to notes |

**Concrete values always win** — if a slide already has `image_path` or concrete `series`, the resolver does not overwrite them.

**`data_query` contract.** The chart-data resolver makes **no** network calls. Real numbers must be sourced by the agent's `webfetch` pre-flight and written as concrete `categories`/`series`; **fabricating chart numbers to pass schema validation is forbidden** — every value must trace to a fetched source.

### Pipeline order

```
agent emits placeholders  ->  resolve_slide_data_list()  ->  schema validation  ->  generate_ppt_from_data()
```

```bash
python -c "
import sys; sys.path.insert(0,'scripts')
from resolvers import resolve_slide_data_list
resolved = resolve_slide_data_list(<JSON_ARRAY>)   # uses resolver.config.json
"
```

Resolution is **non-fatal**: an unconfigured provider or a failed fetch logs a warning and the slide renders without that asset. The build never fails because of a missing resource.

### Configuration

Copy `scripts/resolver.config.example.json` to `scripts/resolver.config.json` (gitignored) and fill in provider keys. An unconfigured provider makes its resolver skip gracefully. Injectable `fetch_fn` / `match_fn` / `search_fn` keys allow custom providers and tests.

## Schema Validation

Every deck is validated against explicit JSON schemas (`scripts/schemas/`, `scripts/schema_validator.py`) for all 8 slide types and `chart_options` (#20). Validation returns **structured, human-readable errors** (slide index + field path + reason) so the agent can self-correct.

```bash
python -c "
import sys; sys.path.insert(0,'scripts')
from schema_validator import validate_slide_data_list
res = validate_slide_data_list(<JSON_ARRAY>, strict=True, density_mode='standard')
print('VALID' if res.is_valid else 'INVALID')
for m in res.error_messages() + res.warning_messages(): print('-', m)
"
```

- **Strict mode** (`strict=True`): missing `notes` and any schema violation block rendering (used by the agent pre-flight gate).
- **Density mode** (`density_mode='standard'|'concise'|'text-heavy'`, optional): runs a per-slide visible-text word-count check against the mode's budget and emits **warnings** on out-of-budget slides. Always non-fatal — never blocks, never promoted by `strict=True`. Omit (`None`) to skip the check entirely.
- **Default mode**: the engine degrades gracefully (skips unknown slide types, defaults bad `chart_type` to `bar`, skips charts missing data) and only aborts on unrecoverable structural breakage (e.g. `slide_data_list` is not an array) with a clear `ValidationError`.

### Two-layer retry (`parse_and_validate`)

For LLM-produced JSON, `parse_and_validate(raw_text)` first **repairs** common mistakes (code fences, trailing commas, single quotes, variable assignments) then **schema-validates** the result — returning clear errors the model can use to self-correct. It also accepts an optional `density_mode` forwarded to the validator.

## Density Modes

A deck-wide **density mode** fixes a per-slide visible-text word budget. It is the primary content-side lever for preventing the text-overflow defect (long content exceeding placeholder boundaries and overlapping neighboring shapes). The agent **defaults to `standard` for the first generation** (auto-downshifted to `concise` for small content areas `< ~30 in²`; a user-stated density intent from the first message is honored) and may adjust the mode **post-generation** per the user's refinement choice (see `pptx-subagent` Stage 5); the validator then warns on any slide whose visible text falls outside the budget.

| Mode | Per-slide words | Use when |
|------|-----------------|----------|
| `concise` | 0–10 | Minimal text, often image-only; keynote/hero decks |
| `standard` ⭐ default | 30–50 | Balanced reporting decks — the safe default |
| `text-heavy` | 75–150 | Dense, document-style decks for self-study/handout |

**What counts toward the budget** — the on-slide visible text only: `title` + `subtitle` + `body` + `body_left` + `body_right`. Markdown emphasis markers (`**`, `_`, backticks) and punctuation-only tokens (the ` — ` / ` - ` / `: ` body-format delimiters) are stripped before counting. Each CJK character counts as one word.

**What is NOT counted** — `notes` (lives in the Notes pane, never renders on the slide), and `chart_slide` `categories`/`series` labels (numeric/temporal, not meaningfully constraining).

**Severity** — out-of-budget slides emit **warnings, never errors**, even in `strict=True` mode. A word-count budget is a soft guideline the agent self-tightens, not a structural rule. `concise` slides at zero words (image-only) are always valid; `title_slide`/`section_header_slide`/`closing_slide` naturally underflow `standard`/`text-heavy` budgets and that underflow is expected/harmless.

```bash
python -c "
import sys; sys.path.insert(0,'scripts')
from density_mode import DENSITY_BUDGETS, DEFAULT_DENSITY_MODE, count_slide_words, validate_density
print(DENSITY_BUDGETS)           # {'concise': (0, 10), 'standard': (30, 50), 'text-heavy': (75, 150)}
print(count_slide_words({'title': 'Hi', 'body': '**Point** — desc here'}))  # 4
print(validate_density(<JSON_ARRAY>, 'standard'))  # [] when all in budget
"
```

## Multi-Stage Generation

For best quality on longer decks, the agent generates in three stages: **outline → critique/review → detail+JSON**, with each JSON stage schema-validated before continuing. The **primary agent no longer pauses** after the outline — the first generation is autonomous with template-aware defaults (self-critique, no pre-generation prompt); post-generation refinements are offered after the file is returned (see `pptx-subagent` Stage 5). A **subagent** runs fully autonomously and skips the refinement prompt too. See `docs/DESIGN-multi-stage-generation.md`.

**Slide count convention.** When the user requests "N pages/slides", that number is the **total** deck size including cover and closing: N ≥ 3 → 1 cover + (N−2) content + 1 closing; N = 2 → cover + 1 content; N = 1 → cover only. The closing slide defaults to `"Thank You"` as its title (matching the `End` layout built-in) with no `subtitle` authored.

**Temp cleanup:** the outline artifact (and any agent-written temp file under `outline_store._TEMP_DIR`, a namespaced system temp dir) is **cleared automatically** after every successful `generate_ppt_from_data` call (default `cleanup_temp=True`). Temp artifacts therefore never pollute the repo or accumulate on disk.

## End-to-End Example: Mixed Text / Image / Chart Deck

A single deck combining text slides, an image slide (via a local `image_path`), and a native chart with concrete values.

```json
[
  {
    "slide_type": "title_slide",
    "title": "Construction Tech 2026",
    "subtitle": "Market & Field Outlook",
    "notes": "KEY MESSAGE: Construction tech is moving from pilot to mainstream.\n\"Good [morning/afternoon], I'm [Name]...\"\nTRANSITION: \"Let's start with the market.\"\nCOACHING: Confident open. Be ready for: \"Is this hype?\" — lead with the growth number."
  },
  {
    "slide_type": "content_slide",
    "title": "Why Now",
    "body": "**Labor gap** - skilled labor shortage accelerates automation\n**Tech maturity** - BIM, IoT, drones now production-ready\n**Cost pressure** - margins demand efficiency",
    "notes": "KEY MESSAGE: Three forces converging.\n\"Three forces are converging right now.\"\nTRANSITION: \"Here's what that means for the market.\"\nCOACHING: Matter-of-fact. Pause after each driver."
  },
  {
    "slide_type": "content_image_slide",
    "title": "Drones on Site",
    "body": "**Aerial surveys** - cut survey time by 60%",
    "image_path": "output/drone_site.png",
    "image_position": "full",
    "notes": "KEY MESSAGE: Drones are already standard on leading sites.\n\"Look at this - one drone flight replaces days of manual surveying.\"\nTRANSITION: \"Now let's see the market numbers.\"\nCOACHING: Let the image land before speaking."
  },
  {
    "slide_type": "chart_slide",
    "title": "Global Market Growth (USD Billion)",
    "chart_type": "bar",
    "categories": ["2022", "2023", "2024", "2025", "2026"],
    "series": [{"name": "Market Size", "values": [14.8, 19.5, 25.1, 31.7, 39.4]}],
    "chart_options": {"legend_position": "bottom", "y_axis_min": 0, "y_axis_max": 45},
    "notes": "KEY MESSAGE: The market nearly triples by 2026.\n\"From fifteen billion to almost forty in four years.\"\nPause. Let the number land.\nTRANSITION: Open for questions.\nCOACHING: Don't over-sell the curve."
  }
]
```

## End-to-End Example: User-Supplied Template (any `.pptx`)

Fill a deck from a template the user brings — no matter its layout names.

```bash
# 1. Point at the user template (path pass-through — default untouched).
TPL=~/my_company_template.pptx

# 2. Learn what the template can serve (which slide_types, content areas).
python -c "
import sys, json; sys.path.insert(0,'scripts')
from ppt_builder import servable_slide_types, get_render_contract
print(json.dumps(servable_slide_types(get_render_contract('$TPL')), indent=2))
"
# → e.g. {"content_slide": {"available": true, "layout": "Content Page", "content_area_in2": 42.1}, ...}
#   Note the layout NAME differs from the default ("Title and Content") — fingerprint
#   matching still resolves it. Author only available slide_types; downshift density
#   if a content_area_in2 is small.

# 3. Render normally — introspection + fingerprint matching happen automatically.
python -c "
import sys, json; sys.path.insert(0,'scripts')
from ppt_builder import generate_ppt_from_data, DEFAULT_OUTPUT_DIR
slide_data = [
  {'slide_type': 'title_slide', 'title': 'Q2 Review', 'subtitle': '2026', 'notes': '...'},
  {'slide_type': 'content_slide', 'title': 'Highlights', 'body': '**A** — x\n**B** — y', 'notes': '...'},
  {'slide_type': 'closing_slide', 'title': 'Thank You', 'notes': '...'},
]
print(generate_ppt_from_data(slide_data, template_path='$TPL', output_path=str(DEFAULT_OUTPUT_DIR / 'from_user_template.pptx')))
"
```

The output deck uses the user template's own layouts, theme, and master — fully native and editable.

## Output Path

Output files saved under `<project_root>/output/`.

## Multi-aspect-ratio output (US-4.6)

Pass `target_size` to render the deck at a **different aspect ratio** than the template's native size — every element (placeholders, background chrome, charts, images) scales proportionally to the new dimensions.

- **Accepted forms**: a preset (`"16:9"`, `"4:3"`, `"1:1"`) or an explicit dict `{"width_in": W, "height_in": H}` (or `width_emu`/`height_emu`).
- **No-op gate**: when the target **ratio** equals the template's native ratio (or `target_size` is omitted), the default native-size path runs unchanged — no rescaling.
- **How it works**: the engine resizes the canvas and proportionally rescales every master/layout shape, then fills the (now target-sized) placeholders exactly as on the native path — so fonts/theme/bullets stay on-brand via normal layout inheritance.
- **Self-describing output**: the output's embedded schema `slide_dimensions` is rewritten to the target size, so the deck is re-usable as a target-sized template. The `<output>.render.json` sidecar records `aspect_ratio` (native→target + scale factors).

```python
generate_ppt_from_data(slide_data, output_path='report_43.pptx', target_size='4:3')
generate_ppt_from_data(slide_data, output_path='report_square.pptx', target_size={'width_in': 7.5, 'height_in': 7.5})
```

CLI: `python ppt_builder.py -d slides.json -o report.pptx --target-size 4:3` (preset or `WxH` inches like `10x7.5`).

## Execution

```bash
python -c "
import json, sys
sys.path.insert(0, 'scripts')
from ppt_builder import generate_ppt_from_data, DEFAULT_OUTPUT_DIR

slide_data = <JSON_ARRAY>
result = generate_ppt_from_data(
    slide_data,
    output_path=str(DEFAULT_OUTPUT_DIR / 'report.pptx'),
    target_size=None,  # US-4.6: '4:3' / '16:9' / '1:1' / {'width_in':..,'height_in':..} or None (native)
)
print(result)
"
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| `slide_data_list` not a JSON array | Raise `ValidationError` (fatal, clear message) |
| Structural schema violation (strict mode) | Raise `ValidationError` with slide index + field path |
| Unknown `slide_type` | Log warning, skip, continue (graceful) |
| Missing placeholder | Log warning, skip field, continue |
| Single slide fails | Log error, skip slide, continue |
| Template file missing | Raise `FileNotFoundError` (fatal) |
| Unknown `chart_type` | Default to `bar`, log warning |
| Missing `categories` or `series` | Skip chart, log warning |
| Invalid `chart_options` field | Ignore, use default |
| `image_path` file not found | Skip image, log warning |
| Unknown `image_position` | Default to `below-title`, log warning |
| Resolver provider unconfigured / fetch failed | Skip asset, log warning (non-fatal) |
| Slide over/under density budget (`density_mode` set) | Validation warning (non-fatal, never blocks, even in strict mode) |

## Output

Returns the **absolute path** of the generated `.pptx` file.

## Speaker Notes Style Guide

Every `notes` field must be a **full English presenter script (~120–180 words)** — what the presenter literally SAYS. Four-part structure:

1. **KEY MESSAGE** — one line: the single takeaway (a crisp declarative).
2. **Verbatim dialogue + stage directions** (the body — this is the part that must be rich):
   - **Quoted blocks** (`"..."`) of complete, natural, speakable sentences — one thought per block. NEVER abstract bullets.
   - **Tie directly to this slide's content** — weave in the real numbers/names/visuals (e.g. "$1M+", "the three cards").
   - **Intersperse stage directions** as imperative prose: `Pause. Let the number land.` / `Walk through the three points left to right.`
   - Cover/closing only: open with `[morning/afternoon]` and `[Name]`.
   - Where natural, include one audience-engagement rhetorical question.
   - Provide 2–4 flowing quote blocks, not a single sentence.
3. **TRANSITION** — one quoted line bridging to the next slide.
4. **COACHING** — concrete delivery guidance, MUST include BOTH: (a) a tone/pacing note AND (b) at least one anticipated question or "be ready for" Q&A.

**Example — GOOD (match this):**
```
KEY MESSAGE: BIM catches clashes on screen — not on site.
"Hold the slide for a second — let them take in the model."
"BIM gives every discipline one shared digital model, so clashes are caught on screen, weeks before anyone pours concrete."
Pause. Let the number land.
"In our pilots, automated clash detection cut rework by up to thirty percent."
TRANSITION: "Now let's take this same data out onto the construction site."
COACHING: Matter-of-fact tone, don't over-sell. Be ready for: "Does BIM work with non-IFC models?" — we ingest seven formats.
```

## Example Interaction

**User**: "Create a 3-page PPT about how AI empowers accounting"
**Action**: Multilingual (match user prompt) → outline (3 slides = 1 cover + 1 content + 1 closing; **shown as info, not confirmed**) → autonomous `standard` density + self-critique (**no pre-gen question**) → JSON → validate → resolve → render → return path → **one multi-select refinement question**.

1. Outline (3 total per the slide-count convention: N=3 → 1 cover + 1 content + 1 closing). Display it with *"Here's the outline I'll generate — proceeding with defaults; you can adjust in the next step"* and continue (no wait):
   ```
   1. [title_slide]   "AI Empowering Accounting" — subtitle: 2026
   2. [content_slide] "Use Cases" — reporting, reconciliation, fraud detection
   3. [closing_slide] "Thank You"
   ```
2. **Density + self-critique (autonomous, no question).** The user said no density word and the default template's content area is normal → effective density = `standard` (30–50 words/slide). Self-critique the outline (consistency/flow/coverage/redundancy/length/template-fit) and proceed. Outline artifact re-saved with `mode='standard'` header. Closing sign-off defaults to none (`presenter_name`/`presenter_email` unset → engine removes the placeholder).
3. JSON (after self-critique + validation with `density_mode='standard'`):
   ```json
   [
     {"slide_type": "title_slide", "title": "AI Empowering Accounting", "subtitle": "2026",
      "notes": "KEY MESSAGE: ...\n\"Good [morning/afternoon], I'm [Name]...\"\nTRANSITION: ...\nCOACHING: ..."},
     {"slide_type": "content_slide", "title": "AI Use Cases",
      "body": "**Automated Reporting** — RPA auto-generates reports\n**Smart Reconciliation** — 99.5%\n**Fraud Detection** — real-time alerts",
      "notes": "KEY MESSAGE: ...\nTRANSITION: ...\nCOACHING: ..."},
     {"slide_type": "closing_slide", "title": "Thank You",
      "notes": "KEY MESSAGE: ...\nTRANSITION: Open for questions.\nCOACHING: ..."}
   ]
   ```
   (The content-slide body lands at ~40 words — within the standard 30–50 budget. The title and closing slides underflow standard, which is expected and ignored. The closing slide has NO `subtitle`/`presenter_name`/`presenter_email` fields — **the engine removes the sign-off placeholder** since `presenter_name` is unset, so no `"Prepared by: Lecturer Name"` bleeds.)
4. Validate → resolve → render → return output path.
5. **Post-generation refinement question (primary agent, one multi-select):** offer the 7 options (Lower/Increase density, Reduce/Add slides, Add sign-off, Change ratio, No adjustment). Example outcome — user picks "No adjustment (Recommended)": workflow ends, file kept as-is. (Or: user picks "Add presenter sign-off" + provides "Jane Doe / jane@x.com" → set the closing fields → one re-render → return new path → workflow ends. **No second refinement prompt.**)

**User**: "帮我制作一份关于数字化转型的PPT"
**Action**: User wrote in Chinese → **generate English content** ("Digital Transformation"). Communicate the outline/status/refinement in Chinese; slides are English.

## Template Introspection Commands

**Check which slide types the template can serve:**
```bash
python -c "
import sys, json; sys.path.insert(0,'.opencode/skills/pptx-generate-slide-skill/scripts')
from ppt_builder import servable_slide_types, get_render_contract
contract = get_render_contract('template/default.pptx')
print(json.dumps(servable_slide_types(contract), indent=2, ensure_ascii=False))
"
```

**Read 2–3 notes from a generated output deck to internalize house style**
(the bundled `template/default.pptx` has 0 slides — read from a previously
generated `output/*.pptx` instead; if none exists yet, use the GOOD example
in the Speaker Notes Style Guide above):
```bash
python -c "
import sys, glob, os; sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0,'.opencode/skills/pptx-generate-slide-skill/scripts')
from pptx import Presentation
fs = sorted(glob.glob('output/*.pptx'), key=os.path.getmtime, reverse=True)
if not fs: print('No output deck yet - see GOOD example in Speaker Notes Style Guide')
else:
    prs = Presentation(fs[0]); slides = list(prs.slides)
    for i in range(min(3, len(slides))):
        print('===== S%d =====' % i, slides[i].notes_slide.notes_text_frame.text)
"
```

## Self-Critique Rubric

Re-read the outline against these 6 dimensions and **revise it yourself** before writing JSON:

- *Consistency* — do titles tell one coherent story?
- *Flow* — does each slide set up the next?
- *Coverage gaps* — obvious missing context.
- *Redundancy* — slides that repeat each other.
- *Length* — right slide count for the ask.
- *Template fit* — if a small content area was reported, density has been downshifted to `concise`; is the planned body still within the concise budget? Are all planned `slide_type`s ones the template can serve?
