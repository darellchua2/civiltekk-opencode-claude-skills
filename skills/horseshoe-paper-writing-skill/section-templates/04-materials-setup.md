# §4 Materials and Experimental Setup — BRIDGE (middle) Template

> **Horseshoe role:** Establish the evidence base. Supplies inputs to the
> Results section (§5).

## Required Subsections

### §4.1 Dataset

```
We evaluate {METHOD NAME} on {DATASET NAME}, a {PROPERTY} dataset of {SAMPLE
COUNT} {ITEMS} collected {LOCATION / TIME PERIOD}. The dataset comprises
{CLASS BREAKDOWN}. {CAPTURE METHOD: sensor model, sampling rate, environmental
conditions}. Table 1 summarizes the class distribution.
```

> **Table 1 placeholder (caption above table):**
> ```
> **Table 1.** Class distribution of {DATASET NAME}.
> | Class     | Train | Val | Test | Total |
> |-----------|-------|-----|------|-------|
> | Class A   | XX    | XX  | XX   | XXX   |
> | Class B   | XX    | XX  | XX   | XXX   |
> | **Total** | XX    | XX  | XX   | XXX   |
> ```

If the dataset is novel, add a sub-paragraph on **ethical / privacy
considerations** and a sub-paragraph on **release plan** (open / restricted /
embargoed).

### §4.2 Pre-processing

```
Raw {INPUT} is first {PRE-PROCESSING STEP 1: e.g., resampled to 48 kHz}, then
{STEP 2: e.g., normalized to zero mean, unit variance}. {OPTIONAL: data
augmentation list with parameters}.
```

### §4.3 Train / Validation / Test Splits

**Critical for ML / engineering papers.** Specify the **split strategy** and
how it prevents leakage.

```
We split the dataset using {STRATEGY: random / stratified / by-site /
leave-one-out cross-validation / held-out subject}. This ensures {WHY: e.g.,
no recordings from the same wall appear in both train and test, preventing
leakage}. The final split is: train = {N} samples, validation = {N} samples,
test = {N} samples (held out completely until final evaluation).
```

### §4.4 Hyperparameters

```
All models use {OPTIMIZER: Adam / SGD} with learning rate {VALUE}, batch size
{VALUE}, and {N} epochs with early stopping (patience = {VALUE}) on
validation {METRIC}. We apply {REGULARIZATION: dropout p=0.X, weight decay
Y}. {OPTIONAL: learning rate schedule}.
```

### §4.5 Hardware

```
Training is performed on a single {GPU MODEL: e.g., NVIDIA RTX 4090, 24 GB}.
Average training time: {HOURS} hours. Inference time per sample: {MS} ms on
GPU, {MS} ms on CPU. Model size: {MB} MB / {M}M parameters.
```

### §4.6 Evaluation Metrics

```
We report {PRIMARY METRIC: accuracy / mAP / IoU} as well as per-class
{PRECISION, RECALL, F1-SCORE}. {OPTIONAL DOMAIN METRIC: e.g., Expected
Calibration Error (ECE) for probability calibration; Cohen's kappa for
inter-annotator agreement}. Statistical significance is assessed via
{TEST: paired t-test / Wilcoxon signed-rank} with significance level α = 0.05.
```

## Self-Check
- [ ] Dataset description includes sample counts AND class distribution.
- [ ] Split strategy explicitly prevents leakage.
- [ ] A **held-out test set** is reported separately from CV — not just CV.
- [ ] Hyperparameters are specified precisely (lr, batch size, epochs,
      stopping criterion).
- [ ] Hardware specified (GPU model, training time, inference time).
- [ ] Evaluation metrics include per-class breakdown, not just accuracy.
- [ ] Statistical test (if used) is named and α stated.

## Mirror Reminder
This section produces the inputs for Results (§5), which in turn supplies
the evidence for the Conclusion (§3.7) contributions. Hold-out results feed
Conclusion ¶ 2 items 1 and 2.
