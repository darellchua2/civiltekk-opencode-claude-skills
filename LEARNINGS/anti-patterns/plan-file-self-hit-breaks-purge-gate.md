# Anti-pattern: Plan-file self-hit breaks purge gate

A tracked `PLANS/PLAN-*.md` whose AC/done-when gates grep repo-wide for a token the plan document itself contains makes the gate unpassable — the verification can never go green while the plan persists (repo precedent: plan files are kept post-merge, e.g. `PLANS/PLAN-507.md`). The self-hit class extends beyond PLAN files: any record written during the pipeline (LEARNINGS candidates, review memos, trace notes) can carry the purged token and falsify the branch's acceptance grep. Purge-style gates must decide the exclusion set up front (`--exclude-dir=PLANS --exclude-dir=LEARNINGS` for historical records) or the offending records must be deleted/token-free at merge — decided in the AC, not discovered at verification time. Reviewers on purge tickets should emit token-free candidates (name the class, not the literal id).

**Confidence:** high
**Scope:** project
**Evidence:** PLANS/PLAN-516.md AC/6.1 vs `git ls-files PLANS/`; code review 2026-09-21 caught the LEARNINGS-candidate variant (token-bearing learning file would have falsified the gate on commit)
**Date:** 2026-09-21
