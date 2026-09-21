# Binding-row fallback token: one shape, every site

- **Category**: convention
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #512

## Rule

When a contract introduces a mechanically-greppable marker (here the portability
binding's fallback row token `Other/none`), the implementing diff normalizes the
token at EVERY insertion site in the same commit — exact case, separator free
(colon/em-dash/middot all fine; descriptive prose may follow the token but not
replace it). Any PLAN coverage probe must grep the delivered token
case-insensitively (`rg -ni 'other/none'`), never an idealized spelling the
diff didn't ship. Inline rows satisfy the canonical block (the 3-bullet block is
the default shape for NEW skills, not a universal requirement — table cells
can't hold it). Mode R ruling on #512; the #515 guard must codify this token.
