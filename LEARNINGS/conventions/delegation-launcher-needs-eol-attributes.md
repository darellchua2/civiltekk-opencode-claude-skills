# A launcher that hands Windows users into bash needs .gitattributes EOL pins

- **Category**: convention
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #474 (review round 1)

## Rule

A default Git-for-Windows clone (core.autocrlf=true) checks out shell scripts
with CRLF; bash dies on `$'\r'`. The old native ps1 never ran bash; the #474
thin launcher does. Any repo whose Windows entrypoint delegates into bash must
ship `*.sh text eol=lf` in .gitattributes (and `*.ps1 text eol=crlf`).
