---
name: complexity-management-skill
description: Manage software complexity by minimizing accidental complexity and clearly expressing essential complexity through KISS, YAGNI, DRY principles
license: Apache-2.0
compatibility: opencode
category: Code Quality
---

## What I do

Reduce accidental complexity (self-inflicted: unclear names, leaky abstractions, unnecessary layers) while expressing essential complexity (inherent problem domain) clearly.

## When to use me

- Reviewing whether an abstraction/module/layer earns its cost
- Symptoms present: change amplification (one simple change → many edits), high cognitive load (can't hold the module in your head), unknown unknowns (can't find what to change)

House stance: aggressive deletion of speculative abstraction; KISS/YAGNI are the defaults; add a layer only when the second consumer actually arrives. Working code beats elegant design; invest complexity budget where change is frequent.

> Removed 2026-09: essential-vs-accidental complexity essays, the three symptom deep-dives with code examples, XP values walkthrough, KISS/YAGNI/DRY explanation catalogs, working-effectively-with-legacy notes — Ousterhout-style textbook content the model already carries.
