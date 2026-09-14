# Horseshoe Mirror Audit — Pairing Table

> **The single artifact that proves the paper is horseshoe-compliant.** Save
> this file alongside the manuscript as `PAPER-<name>-pairing-table.md`.

## How to Use

1. Fill in every row BEFORE declaring the paper done.
2. If a row cannot be filled, the paper has **drift** — return to the
   relevant arm (Intro or Conclusion) and fix it.
3. Re-run after every revision cycle (pre-submission, post-review-response,
   post-camera-ready).

## Pairing Table

### Contributions (mirrors Intro ¶ 4  Conclusion ¶ 2)

| # | Intro contribution (verbatim) | Conclusion answer (verbatim) | Bridge evidence | ✓ |
|---|--------------------------------|-------------------------------|-----------------|---|
| 1 | _{paste from Intro ¶ 4 item 1}_ | _{paste from Conclusion ¶ 2 item 1}_ | §5.1, Table 2 | ☐ |
| 2 | _{paste from Intro ¶ 4 item 2}_ | _{paste from Conclusion ¶ 2 item 2}_ | §4.1, Table 1 | ☐ |
| 3 | _{paste from Intro ¶ 4 item 3}_ | _{paste from Conclusion ¶ 2 item 3}_ | §5.5 | ☐ |
| 4 | _{...}_ | _{...}_ | _{...}_ | ☐ |

**Rule:** The count and order MUST match. If Intro has 3 contributions,
Conclusion ¶ 2 has 3 items in the same order.

### Research Questions (if used)

| # | RQ (Intro) | Answer (Conclusion) | Bridge evidence | ✓ |
|---|------------|----------------------|-----------------|---|
| 1 | _{RQ1 text}_ | _{answer sentence}_ | §5.X | ☐ |
| 2 | _{RQ2 text}_ | _{answer sentence}_ | §5.Y | ☐ |
| 3 | _{RQ3 text}_ | _{answer sentence}_ | §5.Z | ☐ |

### Paragraph-Level Mirror (Intro  Conclusion)

| Intro paragraph | Theme | Conclusion partner | ✓ |
|-----------------|-------|--------------------|---|
| ¶ 1 | Real-world problem | Conclusion ¶ 5 (future work & impact) | ☐ |
| ¶ 2 | Current practice & limitations | Conclusion ¶ 4 (limitations) | ☐ |
| ¶ 3 | Literature gap | Conclusion ¶ 3 (contributions to knowledge) | ☐ |
| ¶ 4 | Approach preview + contributions | Conclusion ¶ 2 (contributions addressed) | ☐ |
| ¶ 5 | Paper organization | Conclusion ¶ 1 (headline finding) | ☐ |

### Front- / Back-Matter Coverage

| Element | Mentioned in Abstract? | Mentioned in Practical Applications? | ✓ |
|---------|------------------------|--------------------------------------|---|
| Contribution 1 | ☐ | ☐ | — |
| Contribution 2 | ☐ | ☐ | — |
| Contribution 3 | ☐ | ☐ | — |
| Headline number | ☐ | ☐ | — |
| Dataset (name + count) | ☐ | n/a | — |
| Limitations | n/a | n/a | — |

## Common Drift Patterns (and fixes)

| Drift | Symptom | Fix |
|-------|---------|-----|
| **Phantom contribution** | Intro ¶ 4 has 3 contributions; Conclusion ¶ 2 has 2 | Add missing item to Conclusion ¶ 2, OR delete the contribution from Intro ¶ 4 |
| **Phantom answer** | Conclusion ¶ 2 has more items than Intro ¶ 4 | Move the extra item to Discussion, OR add a matching Intro contribution |
| **Orphan RQ** | RQ posed in Intro but never explicitly answered | Add explicit "RQ_N: …" answer in Conclusion ¶ 2 or ¶ 3 |
| **New limitation in Conclusion** | Conclusion ¶ 4 introduces a limitation not in §6.5 | Move the limitation to §6.5 first, then reference it in Conclusion ¶ 4 |
| **Asymmetric paragraph order** | Conclusion order does not mirror Intro order | Reorder Conclusion paragraphs to the canonical ¶1→¶5 mirror |
| **Missing abstract contribution** | Abstract omits a contribution listed in Intro ¶ 4 | Add it to the abstract, OR delete the contribution (it's not load-bearing) |
| **Unquantified implication** | Conclusion ¶ 5 / Practical Applications has no number | Cite the headline metric from §5.1 |

## Sign-Off

```
Paper: {PAPER-NAME}
Date: {YYYY-MM-DD}
Auditor: {NAME / AGENT}

Mirror audit: ☐ PASS  ☐ FAIL (drift items: ____)
Journal-submission format checklist (SKILL.md §12): ☐ PASS  ☐ FAIL
Companion skill checks (research-paper-generation-skill §7): ☐ PASS  ☐ FAIL

Action items (if any):
1. ...
2. ...
```
