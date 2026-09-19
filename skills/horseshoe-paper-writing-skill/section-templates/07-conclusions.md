# §7 Conclusions — RIGHT ARM Template

> **Horseshoe role:** Answer the Introduction's promises, point-for-point.
> **No new content.** Every paragraph mirrors Introduction ¶ 1–5 in reverse
> order.

## 5-Paragraph Structure (mirrors §3.1)

### ¶1 — Headline finding (mirrors Intro ¶ 5)

One quantified sentence. The single most important result.

```
This paper presented {METHOD NAME}, achieving {METRIC VALUE} on {DATASET /
TASK}, outperforming the best baseline by {DELTA}.
```

### ¶2 — Contributions, addressed one-by-one (mirrors Intro ¶ 4)

**The most important paragraph.** Must reference the numbered contributions
from Intro ¶ 4 **in the same order**, with the evidence that supports each.

```
Addressing contribution (1), the proposed {METHOD} {PROPERTY} achieves
{METRIC} on {DATASET} (Table 2), with the {KEY MECHANISM} from §3 enabling
{IMPROVEMENT}. For contribution (2), the {DATASET} is, to the best of our
knowledge, the first {PROPERTY} dataset for {TASK}, comprising {COUNT}
samples across {N CLASSES}. For contribution (3), experiments confirm
{QUANTIFIED RESULT}, demonstrating {GENERALIZATION PROPERTY}.
```

**Critical:** If the Introduction had 3 contributions, this paragraph has 3
items. If 4, then 4. **Same order, same count.**

### ¶3 — Contributions to knowledge (mirrors Intro ¶ 3 / gap)

What does the field now know that it didn't before?

```
More broadly, this work contributes to {FIELD} by demonstrating that {KEY
INSIGHT}. This addresses the gap identified in §2, where prior work had not
{GAP DETAIL}. The proposed approach offers a {PROPERTY} alternative to
{CURRENT PRACTICE}.
```

### ¶4 — Limitations (mirrors Intro ¶ 2)

**No new limitations here** — summarize what was already stated in §6.5.

```
This study has limitations that bound our claims. {LIMITATION 1 — same as
§6.5}. {LIMITATION 2}. {LIMITATION 3}. These are discussed in detail in
§6.5.
```

### ¶5 — Future work & broader impact (mirrors Intro ¶ 1)

```
Future work will extend {METHOD} to {ADJACENT PROBLEM}, addressing the
{LIMITATION} noted above. The proposed methodology demonstrates strong
potential for application in {ADJACENT INDUSTRY / DOMAIN}, contributing to
{BROADER GOAL: safer construction, lower maintenance cost, etc.}.
```

## Self-Check (BEFORE Mirror Audit)
- [ ] ¶1 contains exactly one headline number.
- [ ] ¶2 references each numbered contribution from Intro ¶ 4 in the same
      order. **Same count, same numbering.**
- [ ] ¶3 references the gap from §2 / Intro ¶ 3.
- [ ] ¶4 summarizes limitations from §6.5 — **no new limitations**.
- [ ] ¶5 returns to the real-world problem from Intro ¶ 1.
- [ ] No new citations, datasets, or equations introduced.

## Mirror Audit Bridge (run after this section is drafted)

For each numbered contribution in Intro ¶ 4, find the matching sentence in
Conclusion ¶ 2 and write the bridge evidence:

| Intro contribution | Conclusion ¶ 2 sentence | Bridge evidence (§/Table/Fig) |
|--------------------|--------------------------|--------------------------------|
| (1) {text}         | {text}                   | §5.1, Table 2                  |
| (2) {text}         | {text}                   | §4.1, Table 1                  |
| (3) {text}         | {text}                   | §5.5                           |

If any cell cannot be filled — return to the relevant section and fix.
