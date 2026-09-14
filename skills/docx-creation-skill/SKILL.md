---
name: docx-creation-skill
description: >-
  Create, read, edit Word (.docx) — TOCs, headings, letterheads, tracked
  changes, comments, images; report/memo/letter/template deliverables. Not PDFs,
  spreadsheets, or Google Docs.
license: Apache-2.0
compatibility: opencode
category: Framework
---

## What I do

- Create new Word documents (.docx) using docx-js with professional formatting
- Read and analyze existing .docx files using pandoc or raw XML extraction
- Edit existing documents by unpacking, modifying XML, and repacking
- Handle tracked changes (insertions, deletions, comments)
- Convert between formats (.doc to .docx, .docx to PDF, .docx to images)
- Add images, tables, headers, footers, and hyperlinks to documents
- Generate tables of contents with proper heading hierarchy
- Apply page layouts, margins, and multi-column layouts

## When to use me

Use this skill when:
- User mentions "Word doc", "word document", ".docx", or "Word file"
- Creating reports, memos, letters, or templates as Word documents
- Extracting or reorganizing content from .docx files
- Working with tracked changes, comments, or reviewing documents
- Converting documents to/from .docx format
- Adding images, tables, or professional formatting to documents
- Creating documents with tables of contents, page numbers, or letterheads

Do NOT use for:
- PDFs (use PDF-specific tools)
- Spreadsheets (use Excel tools)
- Google Docs (use Google Workspace tools)
- General coding tasks unrelated to document generation

## Prerequisites

- **pandoc**: Text extraction from .docx files
- **docx**: `npm install -g docx` (for creating new documents)
- **LibreOffice**: PDF conversion (auto-configured via `scripts/soffice.py`)
- **Poppler**: `pdftoppm` for converting PDFs to images

## Quick Reference

| Task | Approach |
|------|----------|
| Read/analyze content | `pandoc` or unpack for raw XML |
| Create new document | Use `docx-js` - see Creating New Documents below |
| Edit existing document | Unpack -> edit XML -> repack - see Editing Existing Documents below |

### Converting .doc to .docx

Legacy `.doc` files must be converted before editing:

```bash
python scripts/soffice.py --headless --convert-to docx document.doc
```

### Reading Content

```bash
# Text extraction with tracked changes
pandoc --track-changes=all document.docx -o output.md

# Raw XML access
python scripts/unpack.py document.docx unpacked/
```

### Converting to Images

```bash
python scripts/soffice.py --headless --convert-to pdf document.docx
pdftoppm -jpeg -r 150 document.pdf page
```

### Accepting Tracked Changes

To produce a clean document with all tracked changes accepted:

```bash
python scripts/accept_changes.py input.docx output.docx
```

---

## Creating New Documents

Generate .docx files with JavaScript, then validate. Install: `npm install -g docx`

### Setup
```javascript
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, ImageRun,
        Header, Footer, AlignmentType, PageOrientation, LevelFormat, ExternalHyperlink,
        InternalHyperlink, Bookmark, FootnoteReferenceRun, PositionalTab,
        PositionalTabAlignment, PositionalTabRelativeTo, PositionalTabLeader,
        TabStopType, TabStopPosition, Column, SectionType,
        TableOfContents, HeadingLevel, BorderStyle, WidthType, ShadingType,
        VerticalAlign, PageNumber, PageBreak } = require('docx');

const doc = new Document({ sections: [{ children: [/* content */] }] });
Packer.toBuffer(doc).then(buffer => fs.writeFileSync("doc.docx", buffer));
```

### Validation
After creating the file, validate it. If validation fails, unpack, fix the XML, and repack.
```bash
python scripts/validate.py doc.docx
```

### Page Size

```javascript
// CRITICAL: docx-js defaults to A4, not US Letter
// Always set page size explicitly for consistent results
sections: [{
  properties: {
    page: {
      size: {
        width: 12240,   // 8.5 inches in DXA
        height: 15840   // 11 inches in DXA
      },
      margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } // 1 inch margins
    }
  },
  children: [/* content */]
}]
```

**Common page sizes (DXA units, 1440 DXA = 1 inch):**

| Paper | Width | Height | Content Width (1" margins) |
|-------|-------|--------|---------------------------|
| US Letter | 12,240 | 15,840 | 9,360 |
| A4 (default) | 11,906 | 16,838 | 9,026 |

**Landscape orientation:** docx-js swaps width/height internally, so pass portrait dimensions and let it handle the swap:
```javascript
size: {
  width: 12240,   // Pass SHORT edge as width
  height: 15840,  // Pass LONG edge as height
  orientation: PageOrientation.LANDSCAPE  // docx-js swaps them in the XML
},
// Content width = 15840 - left margin - right margin (uses the long edge)
```

### Styles (Override Built-in Headings)

Use Arial as the default font (universally supported). Keep titles black for readability.

```javascript
const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 24 } } }, // 12pt default
    paragraphStyles: [
      // IMPORTANT: Use exact IDs to override built-in styles
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial" },
        paragraph: { spacing: { before: 240, after: 240 }, outlineLevel: 0 } }, // outlineLevel required for TOC
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial" },
        paragraph: { spacing: { before: 180, after: 180 }, outlineLevel: 1 } },
    ]
  },
  sections: [{
    children: [
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("Title")] }),
    ]
  }]
});
```

### Lists (NEVER use unicode bullets)

```javascript
// WRONG - never manually insert bullet characters
new Paragraph({ children: [new TextRun("* Item")] })  // BAD

// CORRECT - use numbering config with LevelFormat.BULLET
const doc = new Document({
  numbering: {
    config: [
      { reference: "bullets",
        levels: [{ level: 0, format: LevelFormat.BULLET, text: "*", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "numbers",
        levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ]
  },
  sections: [{
    children: [
      new Paragraph({ numbering: { reference: "bullets", level: 0 },
        children: [new TextRun("Bullet item")] }),
      new Paragraph({ numbering: { reference: "numbers", level: 0 },
        children: [new TextRun("Numbered item")] }),
    ]
  }]
});

// Each reference creates INDEPENDENT numbering
// Same reference = continues (1,2,3 then 4,5,6)
// Different reference = restarts (1,2,3 then 1,2,3)
```

### Tables

**CRITICAL: Tables need dual widths** - set both `columnWidths` on the table AND `width` on each cell. Without both, tables render incorrectly on some platforms.

```javascript
// CRITICAL: Always set table width for consistent rendering
// CRITICAL: Use ShadingType.CLEAR (not SOLID) to prevent black backgrounds
const border = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const borders = { top: border, bottom: border, left: border, right: border };

new Table({
  width: { size: 9360, type: WidthType.DXA }, // Always use DXA (percentages break in Google Docs)
  columnWidths: [4680, 4680], // Must sum to table width (DXA: 1440 = 1 inch)
  rows: [
    new TableRow({
      children: [
        new TableCell({
          borders,
          width: { size: 4680, type: WidthType.DXA }, // Also set on each cell
          shading: { fill: "D5E8F0", type: ShadingType.CLEAR }, // CLEAR not SOLID
          margins: { top: 80, bottom: 80, left: 120, right: 120 }, // Cell padding
          children: [new Paragraph({ children: [new TextRun("Cell")] })]
        })
      ]
    })
  ]
})
```

**Table width calculation:**

Always use `WidthType.DXA` - `WidthType.PERCENTAGE` breaks in Google Docs.

```javascript
// Table width = sum of columnWidths = content width
// US Letter with 1" margins: 12240 - 2880 = 9360 DXA
width: { size: 9360, type: WidthType.DXA },
columnWidths: [7000, 2360]  // Must sum to table width
```

### Images

```javascript
// CRITICAL: type parameter is REQUIRED
new Paragraph({
  children: [new ImageRun({
    type: "png", // Required: png, jpg, jpeg, gif, bmp, svg
    data: fs.readFileSync("image.png"),
    transformation: { width: 200, height: 150 },
    altText: { title: "Title", description: "Desc", name: "Name" } // All three required
  })]
})
```

### Page Breaks

```javascript
// CRITICAL: PageBreak must be inside a Paragraph
new Paragraph({ children: [new PageBreak()] })

// Or use pageBreakBefore
new Paragraph({ pageBreakBefore: true, children: [new TextRun("New page")] })
```

### Hyperlinks

```javascript
// External link
new Paragraph({
  children: [new ExternalHyperlink({
    children: [new TextRun({ text: "Click here", style: "Hyperlink" })],
    link: "https://example.com",
  })]
})

// Internal link (bookmark + reference)
new Paragraph({ heading: HeadingLevel.HEADING_1, children: [
  new Bookmark({ id: "chapter1", children: [new TextRun("Chapter 1")] }),
]})
new Paragraph({ children: [new InternalHyperlink({
  children: [new TextRun({ text: "See Chapter 1", style: "Hyperlink" })],
  anchor: "chapter1",
})]})
```

### Table of Contents

```javascript
// CRITICAL: Headings must use HeadingLevel ONLY - no custom styles
new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-3" })
```

### Headers/Footers

```javascript
sections: [{
  properties: {
    page: { margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } // 1440 = 1 inch
  },
  headers: {
    default: new Header({ children: [new Paragraph({ children: [new TextRun("Header")] })] })
  },
  footers: {
    default: new Footer({ children: [new Paragraph({
      children: [new TextRun("Page "), new TextRun({ children: [PageNumber.CURRENT] })]
    })] })
  },
  children: [/* content */]
}]
```

### Critical Rules for docx-js

- **Set page size explicitly** - docx-js defaults to A4; use US Letter (12240 x 15840 DXA) for US documents
- **Never use `\n`** - use separate Paragraph elements
- **Never use unicode bullets** - use `LevelFormat.BULLET` with numbering config
- **PageBreak must be in Paragraph** - standalone creates invalid XML
- **ImageRun requires `type`** - always specify png/jpg/etc
- **Always set table `width` with DXA** - never use `WidthType.PERCENTAGE`
- **Tables need dual widths** - `columnWidths` array AND cell `width`, both must match
- **Use `ShadingType.CLEAR`** - never SOLID for table shading
- **TOC requires HeadingLevel only** - no custom styles on heading paragraphs
- **Override built-in styles** - use exact IDs: "Heading1", "Heading2", etc.
- **Include `outlineLevel`** - required for TOC (0 for H1, 1 for H2, etc.)

---

## Editing Existing Documents

**Follow all 3 steps in order.**

### Step 1: Unpack
```bash
python scripts/unpack.py document.docx unpacked/
```
Extracts XML, pretty-prints, merges adjacent runs.

### Step 2: Edit XML

Edit files in `unpacked/word/`. See XML Reference below for patterns.

**Use "Claude" as the author** for tracked changes and comments, unless the user explicitly requests use of a different name.

**CRITICAL: Use smart quotes for new content.** When adding text with apostrophes or quotes, use XML entities:
```xml
<w:t>Here&#x2019;s a quote: &#x201C;Hello&#x201D;</w:t>
```
| Entity | Character |
|--------|-----------|
| `&#x2018;` | ' (left single) |
| `&#x2019;` | ' (right single / apostrophe) |
| `&#x201C;` | " (left double) |
| `&#x201D;` | " (right double) |

### Step 3: Pack
```bash
python scripts/pack.py unpacked/ output.docx --original document.docx
```
Validates with auto-repair, condenses XML, and creates DOCX. Use `--validate false` to skip.

---

## XML Reference

### Schema Compliance

- **Element order in `<w:pPr>`**: `<w:pStyle>`, `<w:numPr>`, `<w:spacing>`, `<w:ind>`, `<w:jc>`, `<w:rPr>` last
- **Whitespace**: Add `xml:space="preserve"` to `<w:t>` with leading/trailing spaces
- **RSIDs**: Must be 8-digit hex (e.g., `00AB1234`)

### Tracked Changes

**Insertion:**
```xml
<w:ins w:id="1" w:author="Claude" w:date="2025-01-01T00:00:00Z">
  <w:r><w:t>inserted text</w:t></w:r>
</w:ins>
```

**Deletion:**
```xml
<w:del w:id="2" w:author="Claude" w:date="2025-01-01T00:00:00Z">
  <w:r><w:delText>deleted text</w:delText></w:r>
</w:del>
```

**Inside `<w:del>`**: Use `<w:delText>` instead of `<w:t>`.

### Comments

**CRITICAL: `<w:commentRangeStart>` and `<w:commentRangeEnd>` are siblings of `<w:r>`, never inside `<w:r>`.**

```xml
<w:commentRangeStart w:id="0"/>
<w:r><w:t>text</w:t></w:r>
<w:commentRangeEnd w:id="0"/>
<w:r><w:rPr><w:rStyle w:val="CommentReference"/></w:rPr><w:commentReference w:id="0"/></w:r>
```

### Images

1. Add image file to `word/media/`
2. Add relationship to `word/_rels/document.xml.rels`:
```xml
<Relationship Id="rId5" Type=".../image" Target="media/image1.png"/>
```
3. Add content type to `[Content_Types].xml`:
```xml
<Default Extension="png" ContentType="image/png"/>
```
4. Reference in document.xml:
```xml
<w:drawing>
  <wp:inline>
    <wp:extent cx="914400" cy="914400"/>  <!-- EMUs: 914400 = 1 inch -->
    <a:graphic>
      <a:graphicData uri=".../picture">
        <pic:pic>
          <pic:blipFill><a:blip r:embed="rId5"/></pic:blipFill>
        </pic:pic>
      </a:graphicData>
    </a:graphic>
  </wp:inline>
</w:drawing>
```

---

## Dependencies

- **pandoc**: Text extraction
- **docx**: `npm install -g docx` (new documents)
- **LibreOffice**: PDF conversion (auto-configured for sandboxed environments)
- **Poppler**: `pdftoppm` for images

## Best Practices

### Document Creation
- Always set page size explicitly (docx-js defaults to A4)
- Use Arial font for universal compatibility
- Include outlineLevel on headings for TOC support
- Set table widths with DXA, never percentages

### Editing Workflow
- Always unpack before editing XML
- Use smart quote entities for professional typography
- Preserve formatting when adding tracked changes
- Validate after packing

## Design Aesthetics — Avoiding Generic AI Slop

**CRITICAL**: Documents must look intentionally designed and professionally crafted, not like AI-generated templates. Apply these principles alongside the technical formatting rules above.

### Anti-Patterns to AVOID

- **Default template aesthetics**: Avoid documents that look like they came from Word's "New Document" gallery — no generic blue headings, no Calibri 11pt for everything, no default narrow margins
- **Cookie-cutter structure**: Do not produce documents where every section looks identical. Vary layout density — some sections dense with data tables, others with generous whitespace and a pull quote
- **Generic formatting**: Avoid using the same font size and weight throughout. Create dramatic hierarchy: 24pt bold titles, 14pt subtitles, 11pt body, with intentional spacing between levels
- **Template-looking tables**: Default Word tables with equal-width columns, thin borders, and no visual hierarchy scream "auto-generated." Design tables with intentional column widths, header styling, and minimal borders
- **Overused color choices**: No default blue (#0070C0) for headings. No generic gray (#808080) for subtle text. Choose colors that reflect the document's identity
- **Wall of text**: Break up long paragraphs with subheadings, callout boxes, or pull quotes. A page of unbroken 11pt text is the hallmark of AI-generated documents
- **Inconsistent spacing**: Mixed spacing between paragraphs, random margins, or uneven indentation reveals lack of design intention

### Signature Design Elements

Every document should incorporate at least ONE distinctive design choice:

- **Typography hierarchy**: Use at least 3 distinct levels of heading hierarchy with clear size/weight contrast
- **Strategic color accents**: 1-2 accent colors used consistently for headings, borders, or callout boxes — never rainbow
- **Professional table design**: Tables with styled headers (background fill + white text), minimal horizontal-only borders, and intentional column widths
- **Pull quotes or callout boxes**: Key statistics or quotes highlighted in bordered/shaded boxes to break up text
- **Intentional whitespace**: Generous margins (1-1.5 inches), spacing between sections, and breathing room around tables
- **Custom header/footer**: Professional header with document title, footer with page numbers — never blank

### Differentiation Strategy

Before formatting, ask:
1. **What is this document's visual identity?** A financial report looks different from a creative brief
2. **What should the reader feel?** Authority? Warmth? Urgency? Design for that feeling
3. **Does this look like it was designed or generated?** If every element is perfectly uniform, it's too generic
4. **Would a professional designer approve this?** If not, refine spacing, hierarchy, and color choices

### Typography Recommendations

While Arial is the default for compatibility, use weight and size to create distinction:

| Element | Recommended Styling |
|---------|-------------------|
| Document Title | 28-36pt Bold, accent color or black |
| Heading 1 | 20-24pt Bold, accent color |
| Heading 2 | 16-18pt Bold, dark gray |
| Body Text | 11-12pt Regular, black |
| Captions/Notes | 9-10pt Italic, medium gray |
| Table Headers | 10-11pt Bold, white on colored background |

### Document Aesthetic by Type

| Document Type | Recommended Style | Key Characteristics |
|---|---|---|
| Financial Report | Corporate Minimal | Clean tables, blue/dark gray palette, precise alignment |
| Technical Spec | Swiss/International | Grid-based, monospace for code, restrained color |
| Marketing Brief | Modern Professional | Accent colors, pull quotes, varied layout density |
| Legal/Contract | Formal Traditional | Generous margins, serif feel, numbered sections |
| Proposal | Confident & Bold | Strong typography hierarchy, branded color accents |

## Common Issues

### Invalid XML After Edit
**Issue**: Document won't open after XML editing

**Solution**:
- Check element order in `<w:pPr>`
- Add `xml:space="preserve"` to text with whitespace
- Validate with `python scripts/validate.py doc.docx`

### Tables Render Incorrectly
**Issue**: Tables look wrong in Google Docs or other viewers

**Solution**:
- Use `WidthType.DXA` instead of `PERCENTAGE`
- Ensure `columnWidths` sum equals table width
- Set `width` on each cell matching `columnWidths`

### Images Not Displaying
**Issue**: Images appear as broken placeholders

**Solution**:
- Add image to `word/media/` directory
- Add relationship entry in `word/_rels/document.xml.rels`
- Add content type in `[Content_Types].xml`
- Verify `r:embed` matches relationship ID

## Verification Commands

```bash
# Validate document structure
python scripts/validate.py document.docx

# Extract text to verify content
pandoc document.docx -o output.md && cat output.md

# Unpack to inspect XML
python scripts/unpack.py document.docx unpacked/
ls unpacked/word/
```

**Verification Checklist**:
- [ ] Document opens in Word/LibreOffice without errors
- [ ] Page size is correct (US Letter or A4 as intended)
- [ ] Tables render correctly with proper widths
- [ ] Images display properly
- [ ] Tracked changes appear in review pane
- [ ] TOC generates correctly from headings
- [ ] Headers/footers appear on all pages
