
#515 instance (false positive): the reviewer probed its session cwd — a stale
main checkout missing the just-merged #514 metadata — and raised a BLOCK
("test 3 cannot pass; zero os: lines tree-wide") that was false on the actual
feat/515 branch (playwright carries `os: "linux"`; guard ran 5/5 green).
Static traces against a stale tree produce confident, wrong BLOCKs: re-verify
against the real branch HEAD (or state the cwd assumption and ask for a
tree-state probe) before reporting blocking findings.
