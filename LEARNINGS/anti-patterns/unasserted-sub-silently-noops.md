# Anti-pattern: unasserted substitution silently no-ops then gets claimed done

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-10-01
- **Ticket**: #654

## Symptom

A scripted text substitution (python `re.sub(..., count=1)`, `sed -i`, scripted replace) reported success, the step's Done line claimed the edit ("#654 history clause"), but the README diff showed the clause absent — the pattern required `)\n` while the text ends `).\n`, so the substitution matched nothing and no tool complained.

## Rule

Assert every scripted substitution's effect: check the replacement marker exists in the file AFTER writing (`assert 'marker' in text` post-write, or verify replace-count == expected). A Done line may only claim what a post-write read-back confirmed. Related: `amend-after-sed-needs-restage` (sed's other silent trap).

## Evidence

#654 review fix 471446b (2026-10-01): clause landed only after the diff review caught the no-op; post-write assert added in the retry.
