---
name: brd-creation-skill
description: >-
  Create and review BRDs (BABOK/IIBA) — the sponsor-level 'why' between customer
  Vision and internal SRS. Triggers: create brd, business requirements,
  stakeholder requirements, business need.
license: Apache-2.0
compatibility: opencode
category: Framework
---

## What I do

I provide a structured **Business Requirements Document (BRD)** creation workflow following the **BABOK / IIBA** standard — the recognized sponsor-level "why" document in the document ladder.

1. **BABOK BRD Template** — 4-part structure (Business Requirements / Stakeholder Requirements / Solution Requirements Summary / Transition Requirements)
2. **docs/brd/ Naming Convention** — draft files (`BRD-draft-{slug}.md`) renamed to ticket-keyed files (`BRD-{key}.md`) after ticket creation
3. **PLAN Back-Linkage** — bidirectional traceability between BRD and PLAN files
4. **Discovery Interview Workflow** — prompt-first flow that gathers content section-by-section with user confirmation

> **Position in the document ladder:** the BRD is the **sponsor-level** document. It captures the business problem/opportunity, objectives, stakeholder needs, and a high-level solution summary — it is NOT a detailed functional spec (that is the SRS). Flow: **Vision** (customer-facing) → **BRD** (sponsor/stakeholder scope) → **SRS** (internal functional/technical scope). BRD is a **new** document type — there is no "prd" back-compat alias (prd routes to SRS).

## When to use me

Use this skill when:
- A sponsor or business owner needs a **business-level** requirements document (the "why" and "what for", at the business/stakeholder scope)
- Someone says "create brd", "business requirements", "stakeholder requirements", "business need", "business requirements document"
- The customer-facing Vision is signed off and the business case/objectives must be formalized before detailed functional requirements (SRS)
- You need a high-level solution summary + transition requirements (training, migration, org change) — NOT detailed functional acceptance criteria

**Do NOT use for:** detailed functional requirements / acceptance criteria (use `srs-creation-skill`); customer-facing vision (use `vision-creation-skill`).

**Trigger phrases**: "create brd", "business requirements", "stakeholder requirements", "business need", "business requirements document", "write a brd"

## Audience

The BRD is **sponsor/stakeholder-facing**. It encodes business objectives, success criteria, business value, stakeholder needs, a high-level solution summary, and transition requirements (migration, training, organizational change). It is written in business language, not technical specification language. The detailed functional/technical requirements live in the downstream SRS (`srs-creation-skill`).

## Related

- **`requirements-specialist-subagent`** — the agent that authors the BRD (this skill is its template)
- **`srs-creation-skill`** — the downstream document; the BRD's Solution Requirements Summary feeds INTO the SRS's detailed functional requirements
- **`vision-creation-skill`** — the upstream customer-facing doc; the signed Vision feeds INTO the BRD's Business Requirements
- **`interactive-document-rendering-skill`** — shared HTML + DOCX rendering standard (snapshot HTML for BRD)
- **`worktree-pipeline-skill`** — auto-detects draft BRD in `docs/brd/` during PLAN authoring (§6b), renames to ticket key, links in PLAN header
- **`worktree-pipeline-skill`** — downstream consumer; BRD feeds into the PLAN file

---

## BRD Template (BABOK / IIBA)

Every BRD follows the BABOK four-part structure. The header links to the PLAN file (filled when a ticket is created).

### Header

```markdown
# BRD: {Initiative Name}

**Status**: Draft | In Review | Approved
**Author**: {name}
**Date**: {YYYY-MM-DD}
**Vision**: docs/vision/VISION-{slug}.md _(upstream customer-facing doc, if one exists)_
**SRS**: docs/srs/SRS-{key}.md _(downstream internal doc, filled after SRS is authored)_
**PLAN**: PLANS/PLAN-{key}.md _(filled when ticket is created)_
```

---

## Part 1. Business Requirements (from the sponsor)

> The business problem/opportunity, the measurable objectives, and the business value. This is the sponsor-level "why".

### 1.1 Business Problem / Opportunity

```markdown
## 1.1 Business Problem / Opportunity

{What business problem exists today or what opportunity is available? Who is
affected? What is the cost of the status quo?}

**Example**: The current quoting process is entirely manual (email + spreadsheets),
averaging 3 business days per quote and producing a 12% error rate that requires
rework. This caps throughput at ~40 quotes/month and loses an estimated 8% of
leads to competitors with faster turnaround.
```

### 1.2 Business Objectives & Success Criteria

```markdown
## 1.2 Business Objectives & Success Criteria

### Objectives
- {Objective 1 — the business outcome this initiative must deliver}
- {Objective 2}

### Success Criteria (measurable)
| Objective | Metric | Baseline | Target |
|-----------|--------|----------|--------|
| {Objective} | {How measured} | {Current} | {Goal} |

**Example**: Quote turnaround time → baseline 3 days → target < 4 hours for
80% of standard quotes.
```

### 1.3 Business Value / Benefits

```markdown
## 1.3 Business Value

| Benefit | Type | Estimated Value |
|---------|------|-----------------|
| {Benefit} | Revenue / Cost / Efficiency / Risk / Compliance | {Quantified or qualitative} |
```

### 1.4 Background & Business Context

```markdown
## 1.4 Background & Business Context

{What led to this problem/opportunity? What prior decisions, strategic goals,
or market conditions are relevant?}
```

---

## Part 2. Stakeholder Requirements (from stakeholders)

> Needs and expectations of the people affected by or influencing the initiative, plus a stakeholder map.

### 2.1 Stakeholder Map

```markdown
## 2.1 Stakeholder Map

| Stakeholder | Role | Interest / Influence | Engagement |
|-------------|------|----------------------|------------|
| {Name/Group} | {Sponsor / SME / End user / Compliance} | {What they care about; H/M/L influence} | {Inform / Consult / Collaborate / Decide} |
```

### 2.2 Stakeholder Needs & Expectations

```markdown
## 2.2 Stakeholder Needs & Expectations

### {Stakeholder 1}: {Role}
- **Needs**: {What they need from the solution}
- **Expectations**: {What they expect the experience/outcome to be}
- **Pain points**: {Current frustrations}

### {Stakeholder 2}: {Role}
- **Needs**: {...}
```

### 2.3 Assumptions & Constraints (business-level)

```markdown
## 2.3 Assumptions & Constraints

### Assumptions
- {something believed true at the business level}

### Constraints
- {Budgetary, timeline, regulatory, organizational}
```

---

## Part 3. Solution Requirements Summary

> **HIGH-LEVEL capability summary — NOT a detailed functional spec.** This section describes what the solution must do at a capability level, enough to scope the work and feed the downstream SRS. Detailed functional requirements (FR-N with acceptance criteria, NFRs, traceability) belong in the SRS.

### 3.1 Proposed Solution Overview

```markdown
## 3.1 Proposed Solution Overview

{1–2 paragraph description of the proposed solution at a high level — what it
does, the key capabilities, and how it addresses the business problem.
Alternatives considered and why the proposed approach was selected.}
```

### 3.2 Key Capabilities (high-level)

```markdown
## 3.2 Key Capabilities

- **{Capability 1}**: {one-line description of what the solution must be able to do}
- **{Capability 2}**: {one-line description}

### Out of scope
- {Explicitly excluded capabilities}
```

### 3.3 High-Level Business Rules

```markdown
## 3.3 High-Level Business Rules

- {Business rule the solution must enforce} (e.g. "Quotes above $X require manager approval before sending")
```

### 3.4 High-Level Non-Functional Expectations

```markdown
## 3.4 High-Level Non-Functional Expectations

- {Category}: {Expectation} (e.g. "Performance: quote generation < 30s for standard inputs")

> Detailed NFRs (specific targets, measurement methods) belong in the downstream SRS §3.5.
```

---

## Part 4. Transition Requirements

> How the organization moves from the current state to the future state. These are often the most overlooked and most critical for adoption.

### 4.1 Data Migration

```markdown
## 4.1 Data Migration

- {What data must migrate from existing systems? Format, volume, cleansing needs?}
- {One-time vs ongoing sync?}
```

### 4.2 Training & Enablement

```markdown
## 4.2 Training & Enablement

- {Who needs training and on what?}
- {Materials needed: guides, demos, workshops}
```

### 4.3 Organizational Change

```markdown
## 4.3 Organizational Change

- {Process changes, role changes, resistance risks}
- {Communication plan}
```

### 4.4 Cutover / Parallel Run

```markdown
## 4.4 Cutover / Parallel Run

- {Big-bang cutover vs phased rollout vs parallel run?}
- {Rollback plan if the new solution fails}
```

### 4.5 Risks & Dependencies

```markdown
## 4.5 Risks & Dependencies

| Risk / Dependency | Likelihood | Impact | Mitigation / Owner |
|-------------------|-----------|--------|---------------------|
| {Item} | H/M/L | H/M/L | {Action} |
```

---

## docs/brd/ Naming Convention

### Draft (during planning, before ticket exists)

```
docs/brd/BRD-draft-{kebab-slug}.md
```

- Slug derived from BRD title (e.g. "Quote Automation" → `quote-automation`)
- Created by `requirements-specialist-subagent` during the discovery interview
- The `**PLAN**:` field in the header is `_(filled when ticket is created)_`

### Final (after ticket creation)

```
docs/brd/BRD-{ticket-key}.md
```

- Renamed via `git mv` by `worktree-pipeline-skill` §6b during PLAN authoring (preserves git history)
- If the draft was never committed (untracked on the new branch), a plain `mv` + `git add` is used instead

### Bidirectional Linkage

| Direction | Field | Location |
|-----------|-------|----------|
| BRD → PLAN | `**PLAN**: PLANS/PLAN-{key}.md` | BRD header (filled at rename time) |
| PLAN → BRD | `**BRD**: docs/brd/BRD-{key}.md` | PLAN header (injected by worktree-pipeline-skill) |

---

## Rendering

**Render dual outputs per `interactive-document-rendering-skill` (snapshot for BRD):**
- **Interactive HTML** — rendered once at wrap (`docs/brd/{slug}/BRD-{slug}.interactive.html`), snapshot (not living)
- **Word .docx** — formal deliverable for sponsor/stakeholder review & sign-off (`docs/brd/BRD-{slug}.docx`), auto-TOC + hyperlinked headers + section page-breaks

**Image routing:** if a referenced diagram/screenshot must be interpreted, delegate to `image-analyzer-subagent` (do not interpret inline).

---

## Discovery Interview Workflow

The `requirements-specialist-subagent` follows this prompt-first flow (after the doc-type routing decision tree resolves to BRD):

### Step 1: Gather Title & Overview
```
Subagent: "What is the title and brief overview of the business initiative you want a BRD for?"
User: {provides title and overview}
Subagent: "I'll use: Title: '{title}'. Proceed?"
```

### Step 2: Iterate Through BABOK Parts
```
For each part/section (Business Requirements → Stakeholder Requirements → Solution Requirements Summary → Transition Requirements):
  Subagent: "Next: {Section} (e.g. 1.2 Business Objectives & Success Criteria). {Purpose}. What content?"
  User: {provides content or says "skip" — skip keeps the heading}
  Subagent: "Got it. Here's what I'll write: {summary}. Correct?"
```

### Step 3: Confirm Full BRD Before Writing
```
Subagent: "Here's a summary of the BRD:
  - Title: {title}
  - Parts: 1–4 (BABOK, with content)
  - File: docs/brd/BRD-draft-{slug}.md

  Proceed to write?"
User: {yes → write file; no → revise}
```

---

## Return Contract

```
**Status:** [success | partial | failed]
**Output:** docs/brd/BRD-draft-{slug}.md
**Summary:** BRD created (BABOK/IIBA) across 4 parts; written to docs/brd/
**Issues:** [blockers or "None"]
```
