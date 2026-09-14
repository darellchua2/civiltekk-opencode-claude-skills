# §6 Discussion — BRIDGE (right) Template

> **Horseshoe role:** Interpret results. Bridge to the right arm (Conclusion).
> Supplies the "why" behind the numbers in §5.

## Required Subsections

### §6.1 Why the Method Works

Mechanistic explanation, tying back to the Methodology equations.

```
The strong performance of {METHOD} on {TASK} can be attributed to {REASON 1
referencing §3 equation}. Specifically, {EQUATION (N)} ensures {PROPERTY},
which is critical because {DOMAIN REASON}. {REASON 2}.
```

### §6.2 Comparison with Prior Work

Explicit deltas. Be concrete about what differs.

```
Unlike {PRIOR METHOD} (Author Year), which {WHAT PRIOR DOES}, our method
{WHAT OURS DOES DIFFERENTLY}. This results in a {DELTA} improvement on
{METRIC}, primarily because {MECHANISM}.
```

### §6.3 Ablation Interpretation

(If ablations are in §5.6, interpret them here.)

```
The ablation results (Table 5) reveal that {COMPONENT} contributes most
({DELTA} when removed). This aligns with the intuition that {WHY}, and
suggests that future work should focus on {DIRECTION}.
```

### §6.4 Failure Cases

Show 2–3 concrete failures and diagnose.

```
We observe failure cases on {CONDITION}. Fig. 6 shows three representative
examples: (a) {FAILURE TYPE 1}, (b) {FAILURE TYPE 2}, (c) {FAILURE TYPE 3}.
In all cases, {COMMON ROOT CAUSE}. This suggests that {FUTURE IMPROVEMENT
DIRECTION}.
```

### §6.5 Limitations (mandatory)

Be explicit. **Never omit.** Reviewers penalize papers that hide limitations.

```
This study has several limitations. First, {LIMITATION 1 — e.g., dataset
size, geographic scope, sensor type}. Second, {LIMITATION 2 — e.g., assumes
a controlled acoustic environment}. Third, {LIMITATION 3 — e.g.,
computational cost, deployment constraints}. These limitations define the
boundaries within which our claims hold, and motivate the future work
discussed in §7.
```

## Self-Check
- [ ] §6.1 references a specific numbered equation from §3 (or a specific
      component if no equations were used).
- [ ] §6.2 compares against at least 2 prior methods with explicit deltas.
- [ ] §6.4 shows 2–3 concrete failure examples with diagnosis.
- [ ] §6.5 Limitations is **explicit and non-empty**.

## Mirror Reminder
§6.5 Limitations maps **directly** to Conclusion ¶ 4. The same limitations
listed here are what Conclusion ¶ 4 will summarize — **no new limitations
introduced in the Conclusion**. If you find a new limitation while writing
the Conclusion, add it here first.
