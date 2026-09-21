# Provenance pins need ≥2 direct choices; equivalence pins need non-empty selections

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #473 (review round 1)

## Symptom

Two #473 pins were false greens: the provenance pin used ONE direct choice
(a single solo entry cannot expose the attribution bug), and the driver
"equivalence" pin compared only the lengths of an EMPTY selection — while
tui.mjs's header claimed "equivalence is test-pinned".

## Rule

Attribution pins exercise ≥2 direct choices with disjoint dependency closures
and assert each dependency credits its true source. Driver-equivalence pins
compare canonicalized FULL JSON of a non-empty selection. Claim-versus-net:
the enforcement must cover exactly what the claim says.
