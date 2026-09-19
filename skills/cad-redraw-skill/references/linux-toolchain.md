# Linux DWG toolchain

DXF is the default deliverable. DWG is a proprietary container: reading and
writing it on Linux requires an external converter. The skill never requires
one — every DWG path degrades gracefully.

## Converter precedence

`fingerprint.py` and any DWG-writing path resolve converters in this order
and **report which converter ran and at what fidelity**:

1. **ODA File Converter** (via `ezdxf.addons.odafc`) — best coverage,
   including recent DWG versions and version downgrade on export. This is
   also the write path: `scripts/to_dwg.py` converts DXF→DWG through
   `odafc.convert` with a `--version` flag (default ACAD2018). Converter
   failure while ODA is present is a bad-input (exit 1) condition, not an
   environment one.
   - Install: download the Linux `.deb`/`.rpm`/`.tgz` from the Open Design
     Alliance (opendesign.com, free download, closed source).
   - Headless servers: it is a GUI-linked Qt binary — export
     `QT_QPA_PLATFORM=offscreen` (or run under `xvfb-run`) before invoking.
     `to_dwg.py` sets this default itself. Upstream also reads `DISPLAY`
     unconditionally when Xvfb is absent — a DISPLAY-less box without Xvfb
     fails with a named exit-2 error.
2. **LibreDWG** (`dwg2dxf`, open source) — read path only, no install
   hassle (`apt install libredwg-tools` on Debian/Ubuntu). Coverage of older
   DWG releases is solid; the newest formats may fail or degrade — the
   version/producer is recorded in the fingerprint either way. LibreDWG
   write support is incomplete and explicitly out of scope for this skill:
   DWG writing goes through ODA only.
3. **No converter** — fail with a named error and the install hint above.
   No traceback, no partial output.

**Silent no-output runs (exit-code carve-out).** ezdxf v1.4.4
`odafc.convert` constructs but never raises its error when the ODA binary
runs, exits cleanly with empty stderr, and writes no output file;
`to_dwg.py`'s post-check maps this to exit 2 (environment), though on Linux
it can equally be a content-triggered ODA crash — the two are
indistinguishable in this path. Callers must disambiguate before acting:
re-run the converter on a known-good DXF — if the toolchain verifies clean,
treat the input DXF as suspect content. Exit 1 stays reserved for *proven*
content failures; revisit this mapping when a fixed ezdxf release raises on
no-output.

## Fidelity reporting

Every DWG-mediated run states: converter used, source DWG version, and any
entities the converter could not represent. A conversion is never described
as lossless unless the fingerprint diff against the DXF round-trip says so.

## Inherent degradation (leaving AutoCAD, not port defects)

These apply to **any** non-AutoCAD toolchain, including this one:

- **Proxy/custom objects** from ObjectARX applications have no class
  definition outside their origin app — they are dropped or exploded.
  Reported as risk; validate visually.
- **SHX font text** carries no glyph data outside AutoCAD; text survives,
  exact glyph appearance does not.
- **Annotative dimensions** lose their per-scale variants; the dimension
  entities themselves survive.
- **Dynamic blocks** import as anonymous blocks; lookup tables and
  stretch actions do not translate.

When the source fingerprint shows any of these, surface the risk in the
redraw prompt and prefer `pass_with_warnings` or `needs_review` over `pass`.

## FreeCAD

FreeCAD is a documented **import/inspection target**, not a dependency of
this skill: any DXF produced here opens in FreeCAD (`File → Import`, or
`freecadcmd` headless). Constrained-sketch reconstruction is out of scope;
for 3D solids use `the cad-generation-skill (load via skill tool)`.
