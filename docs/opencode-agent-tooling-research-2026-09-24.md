# Agent Tooling Research for a Lean Startup

**Prepared for:** Founder review — reducing manpower through agent help
**Date:** 24 September 2026
**Scope:** Browser connectors for OpenCode, video recording, image/marketing generation, founder productivity (PPTX/DOCX/XLSX and CEO workflows), and financial research
**Companion file:** `OpenCode-Agent-Tooling-Research-2026-09-24.interactive.html` (navigable, dark-mode HTML rendering per the repo's interactive-document-rendering standard; both generated artifacts are gitignored — regenerate them from this markdown source)

---

## 1. Executive Summary

You already run a strong setup. An inventory of this repo (146 skills, 34 agents) shows office-document production and startup workflows are your **deepest** area, image/marketing content is well covered, while two genuine gaps stand out: **general-purpose browser automation** (only Playwright testing and a disabled chrome-devtools MCP exist today) and **financial research data** (spreadsheet modeling exists, but no market/filings data sources). The research below covers what is worth **adding**, ranked by how much founder time each item returns.

**Top recommendations (short version):**

1. **Browser:** You do not need a new "browser plugin" product. Your Docker app config already lists Google's **chrome-devtools MCP — currently disabled**; enabling it is a one-line change [3]. Add Microsoft's **Playwright MCP** (37.5k stars) for general logged-in web work; it explicitly lists OpenCode as a supported client, and its browser-extension mode reuses your real Chrome session — the practical answer to the "Claude in Chrome / Kimi work-browser" experience on OpenCode [1][2]. The OpenCode-specific community plugins exist but are early-stage (30 and 4 stars) [8][9].
2. **Video:** You already generate video (zai-video-skill). The gap is recording and edit-style production. **Remotion** (58.5k stars) ships official agent skills so a coding agent can build and render videos from code [13][14]; Browser Use's **video-use** (23.8k stars) targets video editing by coding agents [15]; GitHub's own **screen-recording skill** covers annotated GIF demos [17].
3. **Image/marketing:** Your Z.AI image skill is the baseline; the strongest additions are the **nanobanana MCP server** (390 stars) wrapping Google's Nano Banana models with 4K output and multi-photo editing [21][22], plus the **official Canva MCP** for brand-templated assets your team can still edit in Canva [23][24].
4. **Founder productivity:** Office docs are already your deepest capability — do not add more document generators. The marginal wins are **anthropics/skills**' brand-guidelines and internal-comms skills (21.3k-star reference library) [25] and a **Google Workspace connector** (official MCP servers, Developer Preview) so the agent pulls material from Gmail/Calendar/Drive itself [26].
5. **Financial research:** Your biggest gap. **sec-edgar-mcp** (355 stars) delivers exact XBRL figures from SEC filings with citation URLs and a DOI [28]; **Alpha Vantage's official MCP** covers markets, construction-relevant commodities (copper, aluminum, fuel), and macro indicators with a free key [30]; **OpenBB** is open-sourcing its whole investment workspace with a Lite edition for small teams [32].

6. **Local-first:** nearly every headline pick *executes* locally but leans on cloud models or APIs. The two genuinely **fully-local additions** are a **ComfyUI MCP server** (image generation on your own GPU, zero per-image cost) and **Fast-Whisper MCP** (offline transcription); Section 9 scores every candidate on local-firstness, maturity, effort, cost, and license.

**Honest caveats up front:** star counts are a popularity proxy, not a quality audit; several "why it's good" claims are vendor self-reported and flagged as such; licensing needs checking before commercial use (Remotion's company-license terms, AGPL for sec-edgar-mcp, proprietary license on Anthropic's document skills) [13][25][28].

---

## 2. Method and How to Read This Report

- Sources were retrieved on **24 September 2026** via web search plus direct fetches of the primary repositories and documentation. Star and commit counts were read from GitHub pages the same day and will drift.
- Every recommendation carries a **"Why (evidence)"** line. Where the only support is the vendor's own claim (common with AI-tool benchmarks), it is marked **[vendor-claimed]** and should be treated as marketing until you test it.
- Claims that could not be verified from a primary source are omitted or explicitly labeled. Nothing here is copied from listicles without checking the underlying repo.
- Citations are numbered `[n]` and resolved in Section 11.

---

## 3. Browser Connectors for OpenCode

**Your baseline:** OpenCode's desktop integration already exposes ~45 built-in browser tools (tabs, navigation, click, type, screenshots). Separately, your repo has Playwright-based *testing* skills (responsive audits) and a **chrome-devtools MCP entry in `opencode_app/opencode.json` that is configured but disabled** — the cheapest win in this whole report is turning that on.

### 3.1 The two safe, mature choices

**Playwright MCP — microsoft/playwright-mcp** [1][2]
- 37.5k stars, 3.2k forks, Apache-2.0, 588 commits (retrieved 24 Sep 2026). Maintained by Microsoft; the README's supported-client list includes **opencode** by name.
- Drives pages through structured accessibility snapshots instead of screenshots, so it needs no vision model and stays cheap on tokens. Three connection modes matter to you: a persistent profile (stays logged in), isolated sessions (clean rooms), and a **Chrome/Edge extension that attaches to your existing logged-in tabs** — the closest open equivalent to Claude-in-Chrome or Kimi's work-browser plugin, without a third-party extension [1][2].
- Independent commentary: a practitioner comparison (Steve Kinney, early 2026) treats Playwright MCP, Chrome DevTools MCP, and Claude in Chrome as complementary rather than interchangeable, and warns that Playwright MCP now defaults to a persistent profile — pass `--isolated` when you want clean-state runs [4].
- Microsoft itself notes coding agents may prefer the newer **Playwright CLI + installable skills** over MCP for token efficiency, keeping MCP for long-running exploratory automation [1]. Both are free.

**Chrome DevTools MCP — ChromeDevTools/chrome-devtools-mcp** [3]
- 52.6k stars, 4.5k forks, Apache-2.0, 1,273 commits (retrieved 24 Sep 2026). Built by the Chrome team; strongest at **performance traces, network inspection, and console debugging** — e.g., auditing your own marketing site or a client portal.
- Caveats read from the README before you adopt it: usage-statistics telemetry is **on by default** (`--no-usage-statistics` to opt out), and performance features may send trace URLs to Google's CrUX API unless disabled [3].

**Fit for you:** enable the already-configured chrome-devtools MCP for diagnostics; add Playwright MCP for "go do this on the web" tasks. Together they cover the use-case that Claude Desktop's browser connector or Kimi's browser plugin serve, inside the tool you already use.

### 3.2 OpenCode-native community plugins (inspected, early-stage)

| Project | Maturity (24 Sep 2026) | Notes |
|---|---|---|
| benjaminshafii/opencode-browser [8] | 30 stars, **1 commit** | Chrome extension inspired by Claude in Chrome. Right direction, single-commit history — a prototype. |
| plyght/opencode-browser [9] | 4 stars, 6 commits | 11 browser tools on Playwright with live visual feedback and persistent sessions. |
| opencode-chrome-devtools (npm) [10] | v1.0.4, ~Aug 2026 | CDP-based plugin advertising "no Chrome extension, no native messaging host." |
| OpenCode Browser (Firefox Add-ons) [11] | Published 23 Aug 2026, no reviews | Lets a local agent drive Firefox via a 127.0.0.1 bridge. |
| OpenCode tab-context (Firefox Add-ons) [12] | 32 users | Pushes open tabs into agent context — lightweight, a different job than automation. |

**Verdict:** none matches the two official servers on maintenance. Watch them; don't build your workflow on them yet. Also notable: **browsercode** [7], a fork of OpenCode by the Browser Use team adding a raw-CDP browser primitive (648 stars) — interesting later, not now.

### 3.3 When you want an autonomous web agent rather than a driven browser

**Browser Use — browser-use/browser-use** [5][6]
- Roughly 99k–112k stars across GitHub surfaces fetched the same day (growing quickly), MIT license. The largest open-source browser-automation framework; ships a **CLI plus an installable SKILL.md** so coding agents can hand it whole web tasks ("fill this application form," "compare these three suppliers' prices").
- Quality signals: active engineering blog, published benchmarks, $17M raise [6]. **Flag:** claims like "completes tasks 3–5x faster" are the vendor's own benchmark [vendor-claimed] [5]. The open-source library runs locally against your own model keys; the commercial cloud (stealth browsers, CAPTCHA solving) is a paid product.
- Use when the task is "achieve this outcome on the web" (scrape supplier catalogs, monitor competitor listings) rather than "operate this page."

---

## 4. Video Recording and Production

**Your baseline:** `zai-video-skill` already generates MP4s from text or a first-frame image (Z.AI CogVideoX). The gaps are (a) **recording** screens/webpages and (b) **edit-style production**. Two different jobs:

### 4.1 Screen / webpage recording (demos, walkthroughs, documentation)

- **GitHub's official screen-recording skill** [17] — an Agent Skill published under GitHub's own name: annotated animated GIF demos and screen recordings for pull requests and documentation (frame capture, timing, GIF creation). Good default because it produces reviewable GIFs rather than raw video.
- **chacebot/mcp-screen-capture** [19] — Playwright + ffmpeg MCP for webpage screenshots, video, and GIFs. Functionally on-point but **1 star, 1 commit** — listed for completeness, not recommended for production.
- **video-capture-mcp** (PyPI) [18] — autonomous macOS/iOS-Simulator/Android screen recording with frame extraction. The most engineered option in this niche, but macOS-centric; you are on Linux, so only relevant if you add a Mac.

### 4.2 Generated/edited video (marketing, floor-plan walkthroughs)

- **Remotion — remotion-dev/remotion** [13][14] — 58,490 stars, 4,451 forks (retrieved 24 Sep 2026). "Make videos programmatically with React." The docs include a coding-agent path with official installable skills (`npx -y skills@latest add remotion-dev/skills`): your agent can scaffold, parametrize, and render MP4s — e.g., an animated 20'×45' floor-plan walkthrough reused across listings with only dimensions changed. **License caution:** Remotion is source-available with special company-size-based licensing terms; read LICENSE.md before commercial use [13].
- **video-use (Browser Use org)** [15] — 23,821 stars, "Edit videos with coding agents." New and fast-moving; worth a pilot for prompt-driven editing (cut, caption, reframe).
- **digitalsamba/claude-code-video-toolkit** [16] — ~1.9k installs reported; bundles Remotion, ElevenLabs, FFmpeg, and Playwright skills into one video workspace. Convenient packaging, third-party maintained.
- **stephengpope/remotion-media-mcp** [20] — 33 stars, 22 commits. MCP server generating raw material — images (Nano Banana Pro), text-to-video clips (Veo 3.1), music (Suno), speech and sound effects (ElevenLabs) — through one kie.ai key. Useful as a feed for Remotion; small project, priced per API.

**Fit for you:** a Remotion template that turns your floor-plan PDFs (like the 20x45 model in `docs/`) into narrated walkthrough videos is the highest-leverage video asset for a construction/property startup: build once, regenerate per unit variant.

---

## 5. Image and Marketing Generation

**Already covered in your repo:** zai-image-generation-skill (text-to-image PNGs), zai-media-subagent, image-analyzer-subagent, startup-pitch-deck-skill, construction-bd-skill (proposals/quotations), wireframer-skill. Additions, in recommended order:

1. **nanobanana-mcp-server — zhongweili/nanobanana-mcp-server** [21][22] — 390 stars, 118 forks, MIT, listed on the official MCP Registry. Wraps Google's Nano Banana image models (Gemini 3.1 Flash Image default; Gemini 3 Pro Image for complex work) with up-to-4K output, multi-reference editing (combine several site photos into one render-style image), and precise text rendering — that last one matters for banners with copy on them. Google's own docs describe the model tiers exposed [22]. Free-tier Gemini API key to start.
2. **Official Canva MCP** [23][24] — remote server at `mcp.canva.com`: generate designs, autofill **brand templates**, search your design library, resize per channel, export PDF/PNG/PPTX/MP4, and return an edit link so a human finishes the design (Canva mandates this "design edit handoff" pattern). Honest limits from Canva's docs: brand-template tools need Canva Pro+, `autofill-design` is Enterprise-only, and custom redirect URIs go through a waitlist — major AI clients already have connector access [23]. Companion skills repo: canva-sdks/canva-skills [24]. Lowest-friction path to on-brand social/marketing assets without hiring a designer.
3. **FLUX-family options** — `mflux-mcp` runs FLUX locally but **requires Apple Silicon (MLX)** — not usable on your Linux box [37]; Replicate-based FLUX MCP wrappers exist but are thin (e.g., 1 star) [38]. Skip unless you specifically need FLUX aesthetics.
4. **ComposioHQ community skills** [34] — `content-research-writer` (researched, cited marketing copy; ~71.7k installs reported by directory listings) and `image-enhancer` (screenshot/asset cleanup). Community-maintained; install per-need.

**Anti-parroting note:** Nano Banana quality claims come from Google's product docs (primary) and the server's README (vendor). Directory install counts are self-reported by the directories [34]. The 30-minute test is generating one real banner set.

---

## 6. Day-to-Day Founder Productivity (PPTX / DOCX / XLSX and CEO Ops)

**Already covered — your deepest area, do not duplicate:** the full pptx pipeline (generate-template / generate-slide / template-modifier), docx-creation-skill, ooxml-editing-skill, xlsx-specialist-skill (including financial-model formatting), office-thumbnail review, pdf-specialist, BRD/SRS/vision document chain, startup-business-docs-skill, startup-pitch-deck-skill, plus docx/pptx/xlsx/office-router/startup-CEO/startup-founder **agents**. Structurally this mirrors Anthropic's document skills already.

What is actually worth adding:

1. **anthropics/skills** [25] — 21.3k stars, 2k forks. The reference Agent Skills library behind Claude's document abilities: pptx (189.4k installs), docx (161.8k), xlsx (143.4k), pdf (168.3k) per the skills.sh registry — you have equivalents, so the value for you is the *other* skills: **brand-guidelines** (apply your brand rules to every generated asset), **internal-comms** (status reports, newsletters, FAQs), **doc-coauthoring**, **theme-factory**. **License caution:** the document skills ship under a proprietary license (stated in each SKILL.md); example skills are Apache-2.0. Fine for internal use; check terms before redistributing inside your installer [25].
2. **Google Workspace official MCP servers** [26] — first-party remote MCP servers for **Gmail, Calendar, Drive, Docs, Sheets, Slides, Chat, People** (Developer Preview; OAuth; per-product endpoints such as `gmailmcp.googleapis.com`). This is the heavyweight answer to "let the agent handle my inbox/calendar/files." Setup needs a Google Cloud project and API enablement; preview status means surfaces can change.
3. **aaronsb/google-workspace-mcp** [27] — 176 stars, 50 forks. One community server covering Gmail, Calendar, Drive, Docs, Sheets, Tasks, Meet, Contacts, with multi-account support. Faster to set up than Google's preview if you want it working this week; review the OAuth scopes yourself since it is community-maintained.
4. **Founder/PM thinking skills** — **deanpeters/Product-Manager-Skills** (6.2k stars: PRDs, prioritization, roadmaps, SaaS metrics) [35] and **Swiftner/Factory-Floor** (startup coaching on Theory of Constraints — "find and work your bottleneck") [36]. Zero infrastructure; useful when you want a structured weekly review instead of freeform chat.

**Sequencing advice:** your agents already produce the documents. The marginal wins are (a) brand-guidelines so output is consistently *your* brand, and (b) a Workspace connector so the agent pulls raw material (email threads, briefs) itself instead of you pasting it.

---

## 7. Financial Research Skills and Servers

Your inventory confirms this is the **open gap**: you model financials in spreadsheets, but no skill connects to market or filings data. Options, tailored to a construction/property startup rather than a trading desk:

1. **sec-edgar-mcp — stefanoamorelli/sec-edgar-mcp** [28] — 355 stars, 94 forks, 249 commits. Connects the agent to SEC EDGAR: company facts, 10-K/10-Q/8-K retrieval with section extraction, balance sheet / income / cash flow parsed from **XBRL with exact numeric precision**, insider Form 3/4/5. Two features serve your "strong citations" requirement directly: every response includes the SEC filing URL for verification, and the project publishes a DOI (10.5281/zenodo.17123166) with a Promptfoo eval suite — unusual rigor here. **License:** AGPL-3.0 (commercial licensing offered by the author) — fine to use; check before embedding in a closed product [28].
2. **edgarmcp / mcp-sec-edgar — lucasastorian** [29] — 5 tools, zero infrastructure, one differentiating feature: **clickable citations linking to the exact element in the original filing HTML**, plus multi-period financials (8 quarters per call; Q4 inferred, splits adjusted). If your workflow is "agent drafts an investor update citing primary sources," this is the most citation-native option found.
3. **Alpha Vantage official MCP — alphavantage/alpha_vantage_mcp** [30] — 205 stars, MIT, 306 commits; remote endpoint `mcp.alphavantage.co` with OAuth; free API key. Broad surface: equities, options, FX, crypto, **commodities (copper, aluminum, WTI, natural gas — usable proxies for construction-material and fuel costs)**, macro indicators (CPI, treasury yields, federal funds rate — the demand-side inputs for housing), earnings-call transcripts, news sentiment. A DataDrivenInvestor roundup (Aug 2026) ranks Alpha Vantage and Financial Modeling Prep as the top tier for MCP market data [31] — editorial opinion, but consistent with the tool surfaces themselves.
4. **Financial Modeling Prep MCP** [31] — company-fundamentals depth (statements, ratios, earnings, filings) behind a paid API with clean schemas; the upgrade when free tiers bind. Community server: imbenrabi/Financial-Modeling-Prep-MCP-Server.
5. **OpenBB** [32][33] — the investment-research platform announced it is **open-sourcing its entire suite** (Workspace, Open Data Platform, Copilot, Excel add-in) under a permissive license and launched **Workspace Lite for small teams** (21 Jul 2026). Its MCP surfaces (`openbb-mcp-server` on PyPI; OpenBB-finance/workspace-mcp) let an agent read dashboards and pull research data. The "build my own mini research desk" endgame — adopt after the two options above prove value.

**Practical starter combo:** Alpha Vantage free key (macro + materials prices) + sec-edgar-mcp (diligence on public competitors/suppliers). Total cost: zero, with primary-source citations built in.

---

## 8. Recommended Starter Stack (Ranked)

| # | Add | Effort | Returns |
|---|---|---|---|
| 1 | Enable the already-configured chrome-devtools MCP (`opencode_app/opencode.json`) | ~5 min | Site diagnostics, traces, console debugging inside OpenCode [3] |
| 2 | Playwright MCP (add to opencode.json `mcp` block) | ~15 min | Agent handles logged-in web work: portals, form filing, research [1][2] |
| 3 | Alpha Vantage MCP free key | ~15 min | Materials-cost and macro tracking with cited data [30] |
| 4 | sec-edgar-mcp | ~30 min | Cited, primary-source diligence on public comps/suppliers [28] |
| 5 | anthropics/skills: brand-guidelines + internal-comms | ~30 min | Consistent brand and comms across every generated document [25] |
| 6 | nanobanana-mcp-server + Gemini free key | ~20 min | 4K marketing visuals, multi-photo editing/compositing [21][22] |
| 7 | Remotion skills + one floor-plan walkthrough template | 1–2 days | Reusable video marketing asset per unit model [13][14] |
| 8 | Canva MCP (waitlist/connector) | waitlist-dependent | On-brand editable designs where your team already works [23] |

Deliberately skipped: the 0–30-star OpenCode browser plugins (too early) [8][9]; mflux/FLUX wrappers (wrong platform or too thin) [37][38]; macOS-only capture tooling [18]; more document generators (you are already deepest-in-class there). Section 9 scores every candidate above on feasibility.

---

## 9. Local-First (Self-Hosted) Considerations and Feasibility Scoring

A practitioner taxonomy worth keeping in mind: **local** (runs on your machine), **self-hosted** (runs on your own server), **hosted** (vendor's cloud) — traded off as control vs convenience [39]. One honesty note before the tables: an MCP server running locally does not make the *intelligence* local. Every candidate below still relies on a cloud LLM unless you separately run local models. What local-first buys you as a founder:

- Client drawings, quotations, and site photos never pass through a third-party SaaS — only your model provider sees what the agent sees.
- Predictable costs: no per-seat or per-call SaaS fees; you pay only model/API usage where a key is involved.
- No forced migrations when a vendor changes pricing, gates features, or shuts down (the Canva waitlist and Chrome DevTools telemetry defaults in this report are small examples of that dependency).

### 9.1 Feasibility Matrix

Maturity counts are GitHub snapshots retrieved 24 Sep 2026. Setup ratings assume terminal comfort; your repo's installers remove most of the friction. "Local-first" is graded on where your *data and processing* live, not where the server process runs.

| Candidate | Type | Local-first | Maturity | Setup | Cost | License | Verdict |
|---|---|---|---|---|---|---|---|
| Browser — Playwright MCP [1] | MCP server | Local execution; model API separate | 37.5k stars | Low (~15 min) | Free | Apache-2.0 | **Adopt now** |
| Browser — Chrome DevTools MCP [3] | MCP server | Local execution; telemetry opt-out | 52.6k stars | Trivial (already configured, disabled) | Free | Apache-2.0 | **Adopt now (enable)** |
| Browser — browser-use (OSS) [5] | Library + agent skill | Local execution; bring-your-own model key | ~99k+ stars | Medium | Free (cloud optional) | MIT | Pilot |
| Video — Remotion + official skills [13] | Framework + skills | Fully local rendering | 58.5k stars | Medium (1–2 days for a template) | Free; company-size license terms | Source-available (custom) | Pilot |
| Video — video-use [15] | Agent video editing | Local processing; young project | 23.8k stars | Medium | Free | MIT | Pilot |
| Video — GitHub screen-recording skill [17] | Skill | Fully local (ffmpeg-based) | GitHub-published | Low | Free | Open source | **Adopt for demos** |
| Video — remotion-media-mcp [20] | MCP server | Cloud (kie.ai) | 33 stars | Low | Paid per API | MIT | Optional |
| Image — zai-image-generation-skill (installed) | Skill | Cloud (Z.AI) | In repo | Done | API-metered | In repo | Keep |
| Image — nanobanana-mcp-server [21] | MCP server | Cloud (Gemini API) | 390 stars | Low (~20 min) | Free tier, then paid | MIT | **Adopt** |
| Marketing — Canva MCP [23] | Remote MCP | Cloud SaaS | Official | Medium (waitlist) | Canva plan required for best tools | Proprietary service | Watch |
| Image — ComfyUI MCP (e.g., joenorton/comfyui-mcp-server) [40] | MCP server + ComfyUI | **Fully local** (your GPU) | Small, fragmented ecosystem | High (GPU + model weights) | Free (hardware only) | Varies by server; ComfyUI GPL-3.0 | Pilot if you have a GPU |
| Image — mflux-mcp [37] | MCP server | Fully local, but Apple-silicon only | Small | Not applicable | Free | MIT | Skip (you are on Linux) |
| Productivity — anthropics/skills: brand-guidelines, internal-comms [25] | Skills | Local instruction packs | 21.3k stars | Low (~30 min) | Free | Apache-2.0 (these); doc skills proprietary | **Adopt** |
| Productivity — Google Workspace MCP (official) [26] | Remote MCP | Cloud (Google) | Developer Preview | Medium (GCP project, APIs) | Needs Google account/Workspace | Google service | Adopt when stable |
| Productivity — aaronsb/google-workspace-mcp [27] | MCP server | Cloud (Google) via local server | 176 stars | Medium | Free | MIT | Alternative to official |
| Finance — sec-edgar-mcp [28] | MCP server | Local server; data pulled from SEC public site | 355 stars | Low–Medium | Free | AGPL-3.0 | **Adopt** |
| Finance — Alpha Vantage MCP [30] | MCP server / remote | Cloud API | 205 stars, official | Low (~15 min) | Free tier, then paid | MIT | **Adopt** |
| Finance — OpenBB [32] | Platform + MCP | Self-hostable | Major; open-source migration underway | High | Free / Lite pricing | Permissive (migration in progress) | Later |
| Local AI — Fast-Whisper MCP [41][42] | MCP server | **Fully local** ASR | Engine mature; wrapper projects small | Medium (model download) | Free | Engine MIT; wrapper varies | Pilot |

### 9.2 Pros and Cons of the Shortlist

| Candidate | Key pros | Key cons |
|---|---|---|
| Playwright MCP [1] | Official; lists opencode as a client; extension mode reuses your real logins; accessibility snapshots are token-cheap | Persistent profile conflicts if two clients share a workspace; snapshot text gets verbose on heavy web apps |
| Chrome DevTools MCP [3] | Best-in-class performance traces, network, and console access; slim mode for light use; official | Telemetry on by default; officially Chrome-only |
| browser-use [5] | Task-level "do this errand" automation; huge community; CLI + skill form | Speed claims are vendor benchmarks; heavy for simple pages; constant cloud upsell |
| Remotion + skills [13] | Programmatic, template-driven marketing video; official agent skills; massive community | React/Node learning curve; company-size license terms; slow renders on weak hardware |
| video-use [15] | Prompt-driven editing from an active, well-funded team | Young; interfaces likely to churn |
| GitHub screen-recording skill [17] | Official, tiny, produces reviewable GIFs for docs and demos | GIFs rather than MP4; no editing capability |
| nanobanana-mcp-server [21] | 4K output; multi-image editing/compositing; accurate text in images; MIT; on the MCP Registry | Cloud — client imagery leaves your machine; API cost after the free tier |
| Canva MCP [23] | Brand templates with a human-finish handoff; exports PPTX/PDF/MP4; where non-technical staff already work | Best tools gated to Pro/Enterprise; waitlist for custom agents; SaaS dependency |
| ComfyUI MCP [40] | Fully local image (and some video/audio) generation; zero per-image cost; keeps client-site renders confidential | Needs an NVIDIA-class GPU and multi-GB model weights; fragmented tooling with no dominant repo; per-style prompt setup effort |
| Fast-Whisper MCP [41][42] | Offline transcription at effectively zero marginal cost; good for meeting/voice notes | Accuracy below top cloud ASR on noisy site audio; large model download; wrapper projects are small |
| anthropics/skills additions [25] | Instant brand and comms consistency across everything your agents produce; maintained upstream | License split (document skills proprietary); instruction packs add no new runtime capability |
| Google Workspace MCP (official) [26] | First-party OAuth and governance; covers Gmail/Calendar/Drive/Docs in one program | Developer Preview churn; GCP setup burden; binds you tighter to Google |
| sec-edgar-mcp [28] | Exact XBRL figures; citation URLs on every response; DOI and published evals | US-listed companies only; AGPL license; free ≠ global coverage |
| Alpha Vantage MCP [30] | Breadth (commodities, macro, transcripts); official; free tier | 25 requests/day free tier; real-time depth requires paid plans |
| OpenBB [32] | Full research workspace going permissive open source; Lite edition for small teams | Heavy for a solo founder today; migration still in progress |

### 9.3 The Two Genuinely Fully-Local Additions

- **ComfyUI MCP — image generation on your own GPU [40].** Several MCP servers bridge agents to a local ComfyUI install (the topic listing itself bills the pattern "local-first, agent-native control plane"); the ecosystem is real but fragmented — no single dominant repo yet, so expect to pick one and tolerate some churn. Prerequisites: ComfyUI, model weights (several GB), and realistically an NVIDIA GPU with 8GB+ VRAM for SDXL-class models. Choose this when marketing volume grows enough that per-image API costs bite, or when renders derive from confidential client-site photos; otherwise nanobanana's free tier is cheaper than your setup time.
- **Fast-Whisper MCP — offline transcription [41][42].** The faster-whisper engine documents up-to-4x-faster-than-OpenAI-Whisper transcription at lower memory [42] (engine-maintainer claim, widely reproduced in the community); MCP wrappers expose it directly to the agent. Natural fit: site-meeting recordings and voice notes, transcribed without any audio leaving your machine. Your cloud alternative (zai-asr-skill) remains the quality baseline for noisy recordings.

**Already local-first in your stack, no action needed:** codegraph (local code index), markitdown and docling (local document conversion — note your own repo docs flag that markitdown uploads audio inputs to a Google service), and OpenCode's built-in browser and file tools [39][43].

---

## 10. Risks, Licenses, and Things I Could Not Verify

- **Licenses:** Anthropic document skills — proprietary (redistribution terms) [25]. Remotion — source-available, company-size licensing; verify before client-facing commercial use [13]. sec-edgar-mcp — AGPL-3.0 [28]. Playwright MCP, Chrome DevTools MCP, browser-use, Alpha Vantage MCP — Apache-2.0/MIT (permissive) [1][3][5][30].
- **Security:** any browser-automation server exposes your logged-in session to the agent; both vendors say so plainly ("not a security boundary" / avoid pushing sensitive data through it) [1][3]. Grant scopes narrowly and keep a separate browser profile for agent work.
- **Telemetry:** Chrome DevTools MCP collects usage statistics by default; opt out with `--no-usage-statistics` [3].
- **Vendor-claimed numbers** (browser-use speed claims [5], directory install counts [34]) were not independently verified and are labeled where used.
- **Maturity risk:** this ecosystem moves weekly; all counts here are a 24 Sep 2026 snapshot. Re-check the top picks' READMEs before installing.

---

## 11. Sources

All sources retrieved 24 September 2026.

1. microsoft/playwright-mcp — GitHub repository and README. https://github.com/microsoft/playwright-mcp
2. Playwright MCP documentation (introduction, browser extension, configuration). https://playwright.dev/mcp/introduction
3. ChromeDevTools/chrome-devtools-mcp — GitHub repository and README. https://github.com/ChromeDevTools/chrome-devtools-mcp
4. Steve Kinney, "Runtime Tools Compared: Playwright MCP, Chrome DevTools MCP, and Claude in Chrome." https://stevekinney.com/courses/self-testing-ai-agents/runtime-tools-compared
5. browser-use/browser-use — GitHub repository, README, PyPI page. https://github.com/browser-use/browser-use
6. Browser Use engineering blog (benchmarks, "The Bitter Lesson of Browser Agents," funding). https://browser-use.com/posts
7. browser-use/browsercode — GitHub repository (OpenCode fork with browser primitive). https://github.com/browser-use/browsercode
8. benjaminshafii/opencode-browser — GitHub repository. https://github.com/benjaminshafii/opencode-browser
9. plyght/opencode-browser — GitHub repository. https://github.com/plyght/opencode-browser
10. opencode-chrome-devtools — npm package page. https://www.npmjs.com/package/opencode-chrome-devtools
11. "OpenCode Browser" — Firefox Add-ons listing (published 2026-08-23). https://addons.mozilla.org/en-US/firefox/addon/opencode-browser
12. "OpenCode" — Firefox Add-ons listing (published 2026-05-11). https://addons.mozilla.org/en-US/firefox/addon/opencode
13. remotion-dev/remotion — GitHub repository and LICENSE. https://github.com/remotion-dev/remotion
14. Remotion documentation — "Creating a new project" (coding-agent workflow, official skills). https://www.remotion.dev/docs
15. browser-use/video-use — GitHub organization listing ("Edit videos with coding agents"). https://github.com/browser-use
16. digitalsamba/claude-code-video-toolkit — listing in Awesome Claude Skills directory. https://awesomeclaude.ai/awesome-claude-skills
17. GitHub official "screen-recording" Agent Skill — listing. https://mcpservers.org/agent-skills/github/screen-recording
18. video-capture-mcp — PyPI package page. https://pypi.org/project/video-capture-mcp
19. chacebot/mcp-screen-capture — GitHub repository. https://github.com/chacebot/mcp-screen-capture
20. stephengpope/remotion-media-mcp — GitHub repository and README. https://github.com/stephengpope/remotion-media-mcp
21. zhongweili/nanobanana-mcp-server — GitHub repository and README. https://github.com/zhongweili/nanobanana-mcp-server
22. Google AI documentation — "Nano Banana image generation." https://ai.google.dev/gemini-api/docs/image-generation
23. Canva MCP documentation (tools, rate limits, plan availability, design edit handoff). https://www.canva.dev/docs/mcp/
24. canva-sdks/canva-skills — GitHub repository (via Cursor marketplace listing). https://github.com/canva-sdks/canva-skills
25. anthropics/skills — GitHub repository; skills/docx and skills/pptx SKILL.md license statements; skills.sh install statistics. https://github.com/anthropics/skills and https://skills.sh/anthropics/skills
26. Google Workspace MCP servers — configuration guides (Gmail, Calendar, Drive, Docs; Developer Preview). https://developers.google.com/workspace/guides/configure-mcp-servers
27. aaronsb/google-workspace-mcp — GitHub repository and README. https://github.com/aaronsb/google-workspace-mcp
28. stefanoamorelli/sec-edgar-mcp — GitHub repository, README, PyPI page (DOI 10.5281/zenodo.17123166). https://github.com/stefanoamorelli/sec-edgar-mcp
29. lucasastorian/edgarmcp (mcp-sec-edgar) — GitHub repository and PyPI page. https://github.com/lucasastorian/edgarmcp and https://pypi.org/project/mcp-sec-edgar/
30. alphavantage/alpha_vantage_mcp — GitHub repository. https://github.com/alphavantage/alpha_vantage_mcp and https://mcp.alphavantage.co/
31. Pranjal Saxena, "Top 10 MCP Servers for Stock Market Data in 2026," DataDrivenInvestor (2026-08-25). https://medium.datadriveninvestor.com/top-10-mcp-servers-for-stock-market-data-in-2026-f62d2173663d
32. OpenBB — open-sourcing announcement and Workspace Lite launch (2026-07-21). https://openbb.co/ and https://openbb.co/blog/introducing-openbb-workspace-lite-for-small-investment-teams
33. OpenBB-finance/workspace-mcp and openbb-mcp-server — GitHub and PyPI. https://github.com/OpenBB-finance/workspace-mcp and https://pypi.org/project/openbb-mcp-server/
34. ComposioHQ/awesome-claude-skills (content-research-writer, image-enhancer) via Awesome Claude Skills directory. https://awesomeclaude.ai/awesome-claude-skills
35. deanpeters/Product-Manager-Skills — via Awesome Claude Skills directory listing. https://awesomeclaude.ai/awesome-claude-skills
36. Swiftner/Factory-Floor — via Awesome Claude Skills directory listing. https://awesomeclaude.ai/awesome-claude-skills
37. alampros/mflux-mcp — GitHub repository (Apple Silicon/MLX requirement). https://github.com/alampros/mflux-mcp
38. kmaurinjones/flux-mcp — via MCP Hub directory listing. https://mcpdir.dev/servers/flux-mcp-server
39. Obot, "Hosted MCP vs Self-Hosted MCP vs Local MCP: Pros and Cons." https://obot.ai/blog/hosted-mcp-vs-self-hosted-mcp-vs-local-mcp-pros-and-cons/
40. ComfyUI MCP ecosystem — GitHub topic "comfyui-mcp" ("local-first, agent-native control plane for ComfyUI") and joenorton/comfyui-mcp-server. https://github.com/topics/comfyui-mcp and https://github.com/joenorton/comfyui-mcp-server
41. BigUncle/Fast-Whisper-MCP-Server — GitHub repository. https://github.com/BigUncle/Fast-Whisper-MCP-Server
42. SYSTRAN/faster-whisper — GitHub repository (engine; speed/memory claims are the maintainer's documentation). https://github.com/SYSTRAN/faster-whisper
43. awesome-selfhosted — general reference for self-hosted service alternatives. https://github.com/awesome-selfhosted/awesome-selfhosted

*Prepared as a working document for founder review. Numbers (stars, installs, dates) are snapshots from the retrieval date; re-verify before any purchase or production commitment.*
