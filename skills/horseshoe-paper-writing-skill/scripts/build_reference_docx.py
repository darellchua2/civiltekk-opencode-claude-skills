#!/usr/bin/env python3
"""Regenerate reference-manuscript.docx — a pandoc reference template for
submission-ready journal manuscripts.

Conventions applied (per horseshoe-paper-writing-skill §7.6 and §2.3 #11):
  - Double line spacing throughout (w:line="480", lineRule="auto")
  - 12pt Times New Roman body font (w:sz="24", rFonts TNR)
  - Applied to: Normal, Heading1-6, Title, Author, Caption, Bibliography, BodyText

Usage:
  python3 build_reference_docx.py [pandoc_binary]

Defaults:
  pandoc_binary = "pandoc" (or discovery via: pandoc, /tmp/pandoc-3.5/bin/pandoc)

Output:
  ../assets/reference-manuscript.docx  (relative to this script's directory)
"""
import os
import re
import sys
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
ASSETS_DIR = SCRIPT_DIR.parent / "assets"
OUTPUT_PATH = ASSETS_DIR / "reference-manuscript.docx"

DOUBLE_SPACING = '<w:spacing w:line="480" w:lineRule="auto" w:after="0" w:before="0" />'
TNR_FONTS = '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman" />'
TNR_SIZES = '<w:sz w:val="24" /><w:szCs w:val="24" />'

STYLES_TO_FORMAT = [
    "Heading1", "Heading2", "Heading3", "Heading4", "Heading5", "Heading6",
    "Title", "Author", "Subtitle", "Caption", "Bibliography",
    "BodyText", "TableCaption", "ImageCaption",
]


def find_pandoc(explicit: str | None) -> str:
    if explicit:
        return explicit
    candidates = ["pandoc", "/tmp/pandoc-3.5/bin/pandoc"]
    for c in candidates:
        try:
            subprocess.run([c, "--version"], capture_output=True, check=True)
            return c
        except (FileNotFoundError, subprocess.CalledProcessError):
            continue
    sys.exit("ERROR: pandoc not found. Install pandoc 3.x or pass its path as arg.")


def export_default_reference(pandoc: str, dest: Path) -> None:
    out = subprocess.run(
        [pandoc, "--print-default-data-file", "reference.docx"],
        capture_output=True, check=True,
    )
    dest.write_bytes(out.stdout)


def patch_styles_xml(xml: str) -> str:
    # 1. Replace bare Normal style
    old_normal = (
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">\n'
        '    <w:name w:val="Normal" />\n    <w:qFormat />\n  </w:style>'
    )
    new_normal = (
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">\n'
        '    <w:name w:val="Normal" />\n    <w:qFormat />\n'
        f'    <w:pPr>{DOUBLE_SPACING}</w:pPr>\n'
        f'    <w:rPr>{TNR_FONTS}{TNR_SIZES}</w:rPr>\n'
        '  </w:style>'
    )
    if old_normal in xml:
        xml = xml.replace(old_normal, new_normal)
        print("  ✓ Normal style: double-spacing + TNR 12pt")
    else:
        print("  ⚠ Normal style pattern not found (pandoc default may have changed)")

    # 2. Update pPrDefault to set document-wide double-spacing
    ppr_default_pattern = re.compile(
        r'(<w:pPrDefault>\s*<w:pPr>)(.*?)(</w:pPr>\s*</w:pPrDefault>)',
        re.DOTALL,
    )
    if ppr_default_pattern.search(xml):
        xml = ppr_default_pattern.sub(r'\1' + DOUBLE_SPACING + r'\3', xml)
        print("  ✓ pPrDefault: double-spacing")
    elif "<w:pPrDefault>" not in xml:
        injection = f"<w:pPrDefault><w:pPr>{DOUBLE_SPACING}</w:pPr></w:pPrDefault>"
        xml = xml.replace("<w:rPrDefault>", injection + "\n    <w:rPrDefault>", 1)
        print("  ✓ Injected pPrDefault (double-spacing)")
    else:
        print("  ⚠ pPrDefault present but pattern didn't match")

    # 3. Apply TNR to named styles
    def set_tnr(style_match: re.Match) -> str:
        block = style_match.group(0)
        if "<w:rFonts" in block:
            block = re.sub(r"<w:rFonts[^/]*/>", TNR_FONTS, block)
        elif "<w:rPr>" in block:
            block = block.replace("<w:rPr>", f"<w:rPr>{TNR_FONTS}", 1)
        return block

    for style_id in STYLES_TO_FORMAT:
        pattern = re.compile(
            r'<w:style[^>]+w:styleId="' + style_id + r'"[^>]*>.*?</w:style>',
            re.DOTALL,
        )
        xml, n = pattern.subn(set_tnr, xml)
        if n:
            print(f"  ✓ {style_id}: TNR applied")

    return xml


def repackage_docx(src_dir: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        dest.unlink()
    with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(src_dir):
            for fn in files:
                fp = Path(root) / fn
                arc = fp.relative_to(src_dir).as_posix()
                zf.write(fp, arc)


def main() -> None:
    pandoc = find_pandoc(sys.argv[1] if len(sys.argv) > 1 else None)
    print(f"Using pandoc: {pandoc}")

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        default_ref = tmp_path / "reference-default.docx"
        print("Step 1: Export pandoc default reference.docx")
        export_default_reference(pandoc, default_ref)

        build_dir = tmp_path / "build"
        build_dir.mkdir()
        print("Step 2: Unzip reference.docx")
        with zipfile.ZipFile(default_ref) as zf:
            zf.extractall(build_dir)

        styles_xml = build_dir / "word" / "styles.xml"
        print("Step 3: Patch styles.xml (double-spacing + TNR 12pt)")
        xml = styles_xml.read_text()
        patched = patch_styles_xml(xml)
        styles_xml.write_text(patched)

        print(f"Step 4: Repackage as {OUTPUT_PATH}")
        repackage_docx(build_dir, OUTPUT_PATH)
        print(f"\n✓ Created {OUTPUT_PATH} ({OUTPUT_PATH.stat().st_size} bytes)")
        print("\nUsage with pandoc:")
        print(
            f"  {pandoc} paper.md -o paper.docx --reference-doc={OUTPUT_PATH} "
            "--from markdown --to docx --reference-links"
        )


if __name__ == "__main__":
    main()
