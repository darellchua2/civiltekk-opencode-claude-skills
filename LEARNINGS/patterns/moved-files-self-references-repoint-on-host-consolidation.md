# Pattern: moved files' self-references repoint on host consolidation

When moving a member's files into a consolidation host, the moved file's own
self-references go stale silently — #603 repointed
`react-performance-guidelines.md:3` (`for react-best-practices-skill` →
`for civiltekk-react-quality-skill route perf`, 1-line diff, body untouched).
Rule: after any consolidation move, grep moved files for the old member name.
