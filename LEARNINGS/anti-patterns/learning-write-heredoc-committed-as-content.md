# Learning write scripted via heredoc committed as content

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #514

## Symptom

A batched LEARNINGS write left `LEARNINGS/anti-patterns/plan-per-file-census-unverified.md`
containing the tail of the creation script itself — literal `EOF`, a second
`cat >> _index.md` heredoc, and `echo OK` — while the companion decisions file
was never created and the two `_index.md` entries were never appended. Gates
stayed green: nothing parses learning files for structure, and the index is
append-only text. Both lessons were stored corrupted and unfindable.

## Fix / Rule

After any scripted learning write, **verify the artifact, not the intention**:
the file contains only its markdown (no shell tokens), the companion files
exist, and `_index.md` gained exactly the new entries. Prefer the file-write
tool over shell heredocs for file bodies; reserve shell for appends, and check
the append landed.
