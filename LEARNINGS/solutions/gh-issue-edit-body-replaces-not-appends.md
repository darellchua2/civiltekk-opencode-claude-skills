# `gh issue edit --body` replaces — appending is fetch-then-write

- **Category**: solution
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #476

## Rule

`gh issue edit --body <text>` **replaces** the entire issue body — there is no
append mode. Any instruction (skill text, agent runbook) that hints "append a
line via `gh issue edit --body`" invites an agent literalizing it into clobbering
the body, acceptance criteria included. The safe pattern is fetch-then-write:

```bash
gh issue view <num> --json body -q .body > /tmp/opencode/body.md
printf '\n### Dependencies\nblocked-by: #<ref>\n' >> /tmp/opencode/body.md
gh issue edit <num> --body-file /tmp/opencode/body.md
```

Found during the #476 code review: the new `blocked-by:` recording rule in
`ticket-creation-skill` initially suggested "follow up with one body append
(`gh issue edit --body`)" — a body-clobber hazard on a real path (creation
order follows intake order, so a dependent listed before its blocker lands
there routinely).
