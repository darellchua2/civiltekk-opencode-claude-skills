# §5 Results — BRIDGE (right) Template

> **Horseshoe role:** Produce the quantitative evidence. This is the most
> heavily cited section by the Conclusion (§3.7).

## Required Subsections

### §5.1 Main Results

The single most important table. Method vs. baselines, best in **bold**,
second-best in dagger/underline. (See SKILL.md §8 for table conventions.)

> **Table 2 placeholder:**
> ```
> **Table 2.** Main results on {DATASET} test set (N={COUNT}). Best in
> **bold**, second-best marked with †.
> | Method              | Accuracy | Precision | Recall | F1    | Params |
> |---------------------|----------|-----------|--------|-------|--------|
> | Baseline A          | XX.X     | XX.X      | XX.X   | XX.X  | X.X M  |
> | Baseline B          | XX.X     | XX.X      | XX.X   | XX.X  | X.X M  |
> | {METHOD (ours)} †   | XX.X     | XX.X      | XX.X   | XX.X  | X.X M  |
> | **{METHOD+TL (ours)}** | **XX.X** | **XX.X** | **XX.X** | **XX.X** | X.X M |
> ```

Always state N (test-set size) in the caption.

### §5.2 Per-Class / Per-Condition Breakdown

Never report only accuracy. Show precision / recall / F1 for each class.

```
Table 3 reports per-class performance. {INTERPRETATION: e.g., "The model
shows balanced performance across classes, with recall on the minority
class reaching XX.X%."}.
```

### §5.3 Figures

Every figure referenced in prose. Captions below figures, self-contained.

```
Fig. 3 shows {WHAT}. {OBSERVATION}. {WHY THIS MATTERS}.
```

> **Fig. 3 placeholder:**
> `![Fig. 3. {Descriptive caption with sample size and metric}.](assets/<figure>.png)`

### §5.4 Cross-Validation / Robustness

```
To assess robustness, we perform {K-FOLD CV / LOOCV / BOOTSTRAP} over {N}
splits. Table 4 reports mean ± standard deviation across {N} seeds. The
relative ordering of methods is consistent across folds (Cohen's d = {VALUE}
between top-2 methods).
```

### §5.5 Out-of-Sample / Generalization

```
To evaluate generalization, we further test on a held-out {SITE / SUBJECT /
MATERIAL} not represented in training. Out-of-sample {METRIC} reaches
{VALUE}, confirming {GENERALIZATION CLAIM}.
```

### §5.6 Ablation Studies (recommended)

Remove each component, show the performance drop.

```
Table 5 reports ablations. Removing {COMPONENT} reduces {METRIC} by {DELTA},
confirming its contribution. Surprisingly, removing {OTHER COMPONENT} has
minimal effect ({DELTA}), suggesting {INTERPRETATION}.
```

## Self-Check
- [ ] Main results table uses **bold** for best, † for second-best.
- [ ] Per-class precision/recall/F1 reported (not just accuracy).
- [ ] Every figure referenced in prose ("Fig. N shows …").
- [ ] Robustness reported across multiple seeds (mean ± std).
- [ ] Out-of-sample / held-out evaluation included.
- [ ] Statistical significance markers (*, **, ***) only where a test was run.
- [ ] No cherry-picked random seed — report mean over N ≥ 3 seeds.

## Mirror Reminder
Table 2's headline numbers are what Conclusion ¶ 1 will quote ("We achieved
X% on Y") and what Practical Applications / Highlights (§2.2) will cite. The
held-out result in §5.5 feeds Conclusion ¶ 5 (broader impact / generalization
claim).
