# §3 Methodology — BRIDGE (left) Template

> **Horseshoe role:** Define the framework. **Must contain a labeled
> architecture block diagram** as Figure 1 (or Figure 2 after dataset
> overview). This section supplies the evidence for Conclusion ¶ 2 item 1.
>
> **Diagram decision:** See SKILL.md §6.2 to decide whether you also need a
> layer-level NN diagram (only required for novel architectures).

## Required Subsections

### §3.1 Overview

One paragraph + the architecture figure. State the inputs, outputs, and the
key intuition in plain prose before any math.

```
Fig. 1 shows the overall architecture of {METHOD NAME}. The pipeline ingests
{INPUT DESCRIPTION} and produces {OUTPUT DESCRIPTION}. The key insight is
{ONE-SENTENCE INSIGHT}. The remainder of this section details each stage.
```

> **Figure 1 placeholder:** `![Fig. 1. Overall architecture of {METHOD NAME}.](assets/framework-architecture.png)`
> B&W-academic-compliant per `research-paper-generation-skill` §3.

### §3.2 Inputs / Data Format

What the method ingests, with formal notation.

```
Let {SYMBOL} ∈ {SPACE} denote the input {TYPE}. We represent each {SAMPLE
TYPE} as a {DIMENSIONS} tensor {SYMBOL}. {OPTIONAL: pre-processing steps}.
```

### §3.3 Components — Stage-by-Stage

For each pipeline stage, decide per SKILL.md §7 whether an equation is
required:

```
**{STAGE NAME}**: {ONE-SENTENCE PURPOSE}. Formally, given {INPUT SYMBOL},
{STAGE NAME} computes

$${OUTPUT SYMBOL} = f_{STAGE}({INPUT SYMBOL}; \theta_{STAGE})$$                (N)

where {DEFINE SYMBOLS}. {RATIONALE FOR DESIGN CHOICE}.
```

**Number every equation** `(1), (2), …` — the Discussion will reference them.
Quote standard equations (softmax, cross-entropy, Adam, attention) only in
prose with a citation; do not re-derive (SKILL.md §7.2).

### §3.4 Output / Decision Rule

How a final classification / regression / decision is produced.

```
The final decision is obtained by {DECISION RULE}. Concretely, {FORMAL
EXPRESSION}. We set the operating threshold $\tau$ to {VALUE} based on
{VALIDATION SET OPTIMIZATION / DOMAIN REQUIREMENT}.
```

### §3.5 Implementation Details (optional, often folded into §4)

Hardware-specific details: framework (PyTorch version), GPU model, inference
time per sample, model size in MB / parameters. Reviewers care about
deployability.

## Diagram Checklist (per SKILL.md §6)

- [ ] System architecture diagram present in §3.1 (mandatory for any method paper).
- [ ] If architecture is novel (new module, new fusion, new multi-head
      output), a layer-level diagram is included as a sub-figure.
- [ ] If using a standard backbone unchanged, cite the original and use a
      single-box representation — **do not** re-draw the standard architecture.
- [ ] B&W encoding: rectangles for layers, dashed arrows for skip / residual
      connections, `⊕`/`⊗` for merge ops, tensor shapes on arrows.

## Self-Check
- [ ] §3.1 contains a figure showing the architecture (mandatory).
- [ ] Every numbered equation is referenced later in the paper.
- [ ] Every symbol is defined at first use (or in a Notation subsection).
- [ ] The decision rule is explicit (not implicit in a softmax argmax).
- [ ] The design rationale for each stage is stated — not just what, but WHY.
- [ ] Standard equations cited, not re-derived.

## Mirror Reminder
Methodology supplies the evidence for **Contribution 1** in Conclusion ¶ 2.
Conclusion ¶ 2 item 1 will say: *"For contribution (1), the proposed {METHOD}
{PROPERTY} achieves {METRIC} by {KEY MECHANISM FROM §3}."*
