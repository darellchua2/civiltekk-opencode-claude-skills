# Windows winget ImageMagick pairs with `magick`, not `convert`

- **Category**: solution
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #513

## Symptom

ascii-diagram-creator gained a `winget install ImageMagick.ImageMagick` row
while its snippet still invoked `convert`. winget installs ImageMagick 7, whose
entry point is `magick`; on Windows plain `convert` resolves to
`System32\convert.exe` (the FAT→NTFS tool) — following the doc produced a
filesystem operation, not a diagram.

## Fix / Rule

A Windows install row must pair with the Windows-invocable command. Where a
skill shows winget ImageMagick, annotate the snippet: "Windows IM7:
`magick convert …`". Generalizes: install docs and usage snippets live or die
together — review them as a pair.
