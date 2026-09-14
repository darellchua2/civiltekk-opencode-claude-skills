---
name: pdf-specialist-skill
description: >-
  Create, read, edit, analyze PDFs — forms, OCR, merge, split, convert,
  watermark, encryption, image extraction. Any PDF/.pdf mention. Not Word or
  spreadsheets.
license: Apache-2.0
compatibility: opencode
category: Framework
---

## What I do

- Extract text and tables from PDFs using pypdf, pdfplumber, or command-line tools (pdftotext)
- Merge, split, and manipulate PDF files (rotate pages, add watermarks, encrypt/decrypt)
- Fill PDF forms (fillable fields via pypdf, non-fillable via text annotations)
- Convert PDFs to images and extract embedded images using poppler-utils
- Create new PDFs from scratch using reportlab (professional reports, tables, complex layouts)
- Perform OCR on scanned PDFs using pytesseract to make them searchable

## When to use me

Use me when you need to work with PDF files:

- **PDF manipulation**: Merge multiple PDFs, split into single pages, rotate pages, add watermarks
- **Text/table extraction**: Extract text from digital PDFs, extract tabular data as structured data
- **PDF creation**: Generate new PDFs from scratch, create reports with tables and formatting
- **Form filling**: Fill fillable PDF forms or add text annotations to non-fillable forms
- **Image operations**: Convert PDF pages to images, extract embedded images, create validation images with field overlays
- **OCR processing**: Make scanned PDFs searchable by performing optical character recognition
- **Encryption**: Add password protection to PDFs or decrypt password-protected files
- **Metadata handling**: Read or modify PDF metadata (title, author, subject, creator)

Do NOT use me when:
- Primary deliverable is a Word document (.docx)
- Primary deliverable is a spreadsheet (Excel, CSV)
- Task is general coding unrelated to PDF processing

## Prerequisites

### Required Tools

- **LibreOffice** (for PDF conversion tasks)
  - Automatically configured by `scripts/soffice.py` on first run
  - Handles sandboxed environments with Unix socket restrictions

### Python Libraries

- **pypdf**: Basic PDF operations (merge, split, rotate, metadata, encryption)
- **pdfplumber**: Advanced text and table extraction with precise coordinates
- **reportlab**: Create new PDFs from scratch with professional formatting
- **pypdfium2**: Fast PDF rendering and image generation (optional, advanced)
- **pdf2image**: Convert PDF pages to PNG images for visual analysis
- **pytesseract**: OCR on scanned PDFs (optional)
- **Pillow**: Image processing for validation images

Install dependencies:
```bash
pip install pypdf pdfplumber reportlab pdf2image pytesseract
```

### Command-Line Tools (Optional)

- **poppler-utils** (pdftotext, pdftoppm, pdfimages): PDF conversion and image extraction
- **qpdf**: Advanced PDF manipulation (merge, split, optimize, repair, encryption)
- **pdftk**: Alternative PDF toolkit (if available)

Install on Ubuntu/Debian:
```bash
sudo apt-get install poppler-utils qpdf pdftk
```

Install on macOS:
```bash
brew install poppler qpdf
```

## Steps

### Step 1: Choose Right Tool for Task

| Task | Recommended Tool | Why |
|-------|----------------|-----|
| Merge/split PDFs | pypdf or qpdf | Fast, reliable for basic operations |
| Extract text | pdfplumber | Preserves layout, better than pypdf.extract_text() |
| Extract tables | pdfplumber | Specialized for table extraction |
| Create PDF from scratch | reportlab | Professional formatting, tables, styles |
| Command-line operations | qpdf, poppler-utils | Fast for batch operations |
| OCR scanned PDFs | pytesseract + pdf2image | Makes scanned content searchable |
| Fill PDF forms | See "PDF Form Filling" section | Specialized workflow below |

### Step 2: Basic PDF Operations

#### Read and Extract Text

```python
from pypdf import PdfReader

# Read a PDF
reader = PdfReader("document.pdf")
print(f"Pages: {len(reader.pages)}")

# Extract text
text = ""
for page in reader.pages:
    text += page.extract_text()
print(text)
```

#### Extract Text with Layout (pdfplumber)

```python
import pdfplumber

with pdfplumber.open("document.pdf") as pdf:
    for page in pdf.pages:
        text = page.extract_text()
        print(text)
```

#### Extract Tables

```python
import pdfplumber
import pandas as pd

with pdfplumber.open("document.pdf") as pdf:
    all_tables = []
    for page in pdf.pages:
        tables = page.extract_tables()
        for table in tables:
            if table:
                df = pd.DataFrame(table[1:], columns=table[0])
                all_tables.append(df)

# Combine all tables
if all_tables:
    combined_df = pd.concat(all_tables, ignore_index=True)
    combined_df.to_excel("extracted_tables.xlsx", index=False)
```

#### Merge PDFs

```python
from pypdf import PdfWriter, PdfReader

writer = PdfWriter()
for pdf_file in ["doc1.pdf", "doc2.pdf", "doc3.pdf"]:
    reader = PdfReader(pdf_file)
    for page in reader.pages:
        writer.add_page(page)

with open("merged.pdf", "wb") as output:
    writer.write(output)
```

#### Split PDF

```python
from pypdf import PdfWriter, PdfReader

reader = PdfReader("input.pdf")
for i, page in enumerate(reader.pages):
    writer = PdfWriter()
    writer.add_page(page)
    with open(f"page_{i+1}.pdf", "wb") as output:
        writer.write(output)
```

#### Rotate Pages

```python
from pypdf import PdfReader, PdfWriter

reader = PdfReader("input.pdf")
writer = PdfWriter()

page = reader.pages[0]
page.rotate(90)  # Rotate 90 degrees clockwise
writer.add_page(page)

with open("rotated.pdf", "wb") as output:
    writer.write(output)
```

#### Extract Metadata

```python
from pypdf import PdfReader

reader = PdfReader("document.pdf")
meta = reader.metadata
print(f"Title: {meta.title}")
print(f"Author: {meta.author}")
print(f"Subject: {meta.subject}")
print(f"Creator: {meta.creator}")
```

### Step 3: Create PDFs from Scratch

#### Basic PDF Creation

```python
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

c = canvas.Canvas("hello.pdf", pagesize=letter)
width, height = letter

# Add text
c.drawString(100, height - 100, "Hello World!")
c.drawString(100, height - 120, "This is a PDF created with reportlab")

# Add a line
c.line(100, height - 140, 400, height - 140)

# Save
c.save()
```

#### Create PDF with Multiple Pages

```python
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.styles import getSampleStyleSheet

doc = SimpleDocTemplate("report.pdf", pagesize=letter)
styles = getSampleStyleSheet()
story = []

# Add content
title = Paragraph("Report Title", styles['Title'])
story.append(title)
story.append(Spacer(1, 12))

body = Paragraph("This is body of report. " * 20, styles['Normal'])
story.append(body)
story.append(PageBreak())

# Page 2
story.append(Paragraph("Page 2", styles['Heading1']))
story.append(Paragraph("Content for page 2", styles['Normal']))

# Build PDF
doc.build(story)
```

#### Subscripts and Superscripts (IMPORTANT)

**Never use Unicode subscript/superscript characters (₀₁₂₃₄₅₆₇₈₉, ⁰¹²³⁴⁵⁶⁷⁸⁹) in ReportLab PDFs.** The built-in fonts do not include these glyphs, causing them to render as solid black boxes.

Instead, use ReportLab's XML markup tags:

```python
from reportlab.platypus import Paragraph
from reportlab.lib.styles import getSampleStyleSheet

styles = getSampleStyleSheet()

# Subscripts: use <sub> tag
chemical = Paragraph("H<sub>2</sub>O", styles['Normal'])

# Superscripts: use <super> tag
squared = Paragraph("x<super>2</super> + y<super>2</super>", styles['Normal'])
```

For canvas-drawn text (not Paragraph objects), manually adjust font size and position rather than using Unicode subscripts/superscripts.

### Step 4: Command-Line Tools

#### pdftotext (poppler-utils)

```bash
# Extract text
pdftotext input.pdf output.txt

# Extract text preserving layout
pdftotext -layout input.pdf output.txt

# Extract specific pages
pdftotext -f 1 -l 5 input.pdf output.txt  # Pages 1-5
```

#### qpdf

```bash
# Merge PDFs
qpdf --empty --pages file1.pdf file2.pdf -- merged.pdf

# Split pages
qpdf input.pdf --pages . 1-5 -- pages1-5.pdf
qpdf input.pdf --pages . 6-10 -- pages6-10.pdf

# Rotate pages
qpdf input.pdf output.pdf --rotate=+90:1  # Rotate page 1 by 90 degrees

# Remove password
qpdf --password=mypassword --decrypt encrypted.pdf decrypted.pdf
```

#### pdfimages (poppler-utils)

```bash
# Extract all images
pdfimages -j input.pdf output_prefix

# This extracts all images as output_prefix-000.jpg, output_prefix-001.jpg, etc.
```

### Step 5: Common Tasks

#### Add Watermark

```python
from pypdf import PdfReader, PdfWriter

# Create watermark (or load existing)
watermark = PdfReader("watermark.pdf").pages[0]

# Apply to all pages
reader = PdfReader("document.pdf")
writer = PdfWriter()

for page in reader.pages:
    page.merge_page(watermark)
    writer.add_page(page)

with open("watermarked.pdf", "wb") as output:
    writer.write(output)
```

#### Extract Images

```bash
# Using pdfimages (poppler-utils)
pdfimages -j input.pdf output_prefix
```

#### Password Protection

```python
from pypdf import PdfReader, PdfWriter

reader = PdfReader("input.pdf")
writer = PdfWriter()

for page in reader.pages:
    writer.add_page(page)

# Add password
writer.encrypt("userpassword", "ownerpassword")

with open("encrypted.pdf", "wb") as output:
    writer.write(output)
```

#### Extract Text from Scanned PDFs (OCR)

```python
# Requires: pip install pytesseract pdf2image
import pytesseract
from pdf2image import convert_from_path

# Convert PDF to images
images = convert_from_path('scanned.pdf')

# OCR each page
text = ""
for i, image in enumerate(images):
    text += f"Page {i+1}:\n"
    text += pytesseract.image_to_string(image)
    text += "\n\n"

print(text)
```

## PDF Form Filling

### CRITICAL: Complete These Steps In Order

If you need to fill out a PDF form, **do not skip ahead**. Follow this workflow exactly:

1. Check if PDF has fillable form fields
2. If fillable: Extract field info → Convert to images → Create field values → Fill
3. If non-fillable: Extract structure → Validate → Create field values → Fill

### Step 1: Check for Fillable Fields

```bash
python scripts/check_fillable_fields.py <file.pdf>
```

This script prints:
- "This PDF has fillable form fields" — Proceed to "Fillable Fields" section
- "This PDF does not have fillable form fields" — Proceed to "Non-fillable Fields" section

### Step 2A: Fillable Fields Workflow

If PDF has fillable form fields:

#### 2A.1: Extract Field Information

```bash
python scripts/extract_form_field_info.py <input.pdf> <field_info.json>
```

This creates `field_info.json` with:
- `field_id`: Unique ID for the field
- `page`: Page number (1-based)
- `rect`: Bounding box in PDF coordinates ([left, bottom, right, top])
- `type`: Field type ("text", "checkbox", "radio_group", or "choice")

For checkboxes, includes:
- `checked_value`: Set field to this value to check
- `unchecked_value`: Set field to this value to uncheck

For radio groups, includes:
- `radio_options`: List of possible choices with `value` and `rect`

For choice fields, includes:
- `choice_options`: List of possible choices with `value` and `text`

#### 2A.2: Convert PDF to Images

```bash
python scripts/convert_pdf_to_images.py <file.pdf> <output_directory/>
```

Then analyze the images to determine the purpose of each form field. Convert bounding box PDF coordinates to image coordinates as needed.

#### 2A.3: Create Field Values JSON

Create `field_values.json` with values to enter for each field:

```json
[
  {
    "field_id": "last_name",
    "description": "The user's last name",
    "page": 1,
    "value": "Simpson"
  },
  {
    "field_id": "Checkbox12",
    "description": "Checkbox to be checked if user is 18 or over",
    "page": 1,
    "value": "/On"
  }
]
```

Important:
- `field_id` must match the ID from `field_info.json`
- `page` must match the page number from `field_info.json`
- For checkboxes: Use the `checked_value` to check, or `unchecked_value` to uncheck
- For radio groups: Use one of the `value` values from `radio_options`

#### 2A.4: Fill the PDF

```bash
python scripts/fill_fillable_fields.py <input.pdf> <field_values.json> <output.pdf>
```

The script:
- Verifies that field IDs and values are valid
- If it prints error messages, correct the appropriate fields and try again
- Creates a filled-in PDF with all form fields populated

### Step 2B: Non-fillable Fields Workflow

If PDF does not have fillable form fields, you'll add text annotations.

#### 2B.1: Extract Form Structure

```bash
python scripts/extract_form_structure.py <input.pdf> form_structure.json
```

This creates `form_structure.json` containing:
- **labels**: Every text element with exact coordinates (x0, top, x1, bottom in PDF points)
- **lines**: Horizontal lines that define row boundaries
- **checkboxes**: Small square rectangles that are checkboxes (with center coordinates)
- **row_boundaries**: Row top/bottom positions calculated from horizontal lines

**Check the results**:
- If `form_structure.json` has meaningful labels (text elements that correspond to form fields), use **Approach A: Structure-Based Coordinates**
- If PDF is scanned/image-based with few or no labels, use **Approach B: Visual Estimation**

#### 2B.2: Approach A - Structure-Based Coordinates (Preferred)

Use this when `extract_form_structure.py` found text labels in the PDF.

**Analyze the structure**:
1. Identify label groups: Adjacent text elements that form a single label (e.g., "Last" + "Name")
2. Identify row structure: Labels with similar `top` values are in the same row
3. Identify field columns: Entry areas start after label ends (x0 = label.x1 + gap)
4. Use checkbox coordinates directly from the structure

**Create fields.json**:

For text fields:
- entry x0 = label x1 + 5 (small gap after label)
- entry x1 = next label's x0, or row boundary
- entry top = same as label top
- entry bottom = row boundary line below, or label bottom + row_height

For checkboxes:
- Use the checkbox rectangle coordinates directly from form_structure.json

```json
{
  "pages": [
    {"page_number": 1, "pdf_width": 612, "pdf_height": 792}
  ],
  "form_fields": [
    {
      "page_number": 1,
      "description": "Last name entry field",
      "field_label": "Last Name",
      "label_bounding_box": [43, 63, 87, 73],
      "entry_bounding_box": [92, 63, 260, 79],
      "entry_text": {"text": "Smith", "font_size": 10}
    }
  ]
}
```

**Important**: Use `pdf_width` and `pdf_height` and coordinates directly from form_structure.json.

#### 2B.3: Approach B - Visual Estimation (Fallback)

Use this when PDF is scanned/image-based and structure extraction found no usable text labels.

**B.3.1: Convert PDF to Images**

```bash
python scripts/convert_pdf_to_images.py <input.pdf> <images_dir/>
```

**B.3.2: Initial Field Identification**

Examine each page image to identify form sections and get rough estimates:
- Form field labels and their approximate positions
- Entry areas (lines, boxes, or blank spaces for text input)
- Checkboxes and their approximate locations

**B.3.3: Zoom Refinement (CRITICAL for accuracy)**

For each field, crop a region around the estimated position to refine coordinates precisely:

```bash
magick <page_image> -crop <width>x<height>+<x>+<y> +repage <crop_output.png>
```

Where:
- `<x>, <y>` = top-left corner of crop region (use rough estimate minus padding)
- `<width>, <height>` = size of crop region (field area plus ~50px padding on each side)

Example:
```bash
magick images_dir/page_1.png -crop 300x80+50+120 +repage crops/name_field.png
```

(Note: if `magick` command isn't available, try `convert` with the same arguments.)

**Convert crop coordinates back to full image coordinates**:
- full_x = crop_x + crop_offset_x
- full_y = crop_y + crop_offset_y

Example: If crop started at (50, 120) and entry box starts at (52, 18) within crop:
- entry_x0 = 52 + 50 = 102
- entry_top = 18 + 120 = 138

**B.3.4: Create fields.json with Refined Coordinates**

```json
{
  "pages": [
    {"page_number": 1, "image_width": 1700, "image_height": 2200}
  ],
  "form_fields": [
    {
      "page_number": 1,
      "description": "Last name entry field",
      "field_label": "Last Name",
      "label_bounding_box": [120, 175, 242, 198],
      "entry_bounding_box": [255, 175, 720, 218],
      "entry_text": {"text": "Smith", "font_size": 10}
    }
  ]
}
```

**Important**: Use `image_width`/`image_height` and refined pixel coordinates from the zoom analysis.

#### 2B.4: Validate Bounding Boxes (Both Approaches)

Before filling, check your bounding boxes for errors:

```bash
python scripts/check_bounding_boxes.py fields.json
```

This checks for:
- Intersecting bounding boxes (which would cause overlapping text)
- Entry boxes that are too small for the specified font size

Fix any reported errors in `fields.json` before proceeding.

#### 2B.5: Fill the Non-fillable Form

```bash
python scripts/fill_pdf_form_with_annotations.py <input.pdf> fields.json <output.pdf>
```

The script:
- Auto-detects the coordinate system (PDF or image) and handles conversion
- Adds text annotations at the specified locations
- Creates a filled PDF with all annotations applied

#### 2B.6: Verify Output

Convert the filled PDF to images and verify text placement:

```bash
python scripts/convert_pdf_to_images.py <output.pdf> <verify_images/>
```

If text is mispositioned:
- **Approach A**: Check that you're using PDF coordinates from form_structure.json with `pdf_width`/`pdf_height`
- **Approach B**: Check that image dimensions match and coordinates are accurate pixels
- **Hybrid**: Ensure coordinate conversions are correct for visually-estimated fields

## Best Practices

### Library Selection

- **pypdf**: Best for basic PDF operations (merge, split, rotate, metadata)
- **pdfplumber**: Best for text and table extraction with layout preservation
- **reportlab**: Best for creating new PDFs with professional formatting
- **pypdfium2**: Best for fast PDF rendering and image generation (advanced)
- **qpdf/poppler-utils**: Best for command-line batch operations

### Working with pypdf

- Page indices are 0-based (first page is index 0)
- Use `data_only=True` to read form field values: `PdfReader(file, data_only=True)`
- Metadata is available via `reader.metadata`

### Working with pdfplumber

- Coordinates: (x0, top, x1, bottom) where y=0 is at TOP of page
- Use `extract_words()` for text with character-level coordinates
- Use `extract_tables()` for structured table data
- For complex layouts, adjust `snap_tolerance` and `intersection_tolerance`

### Performance Tips

- For large PDFs: Use streaming approaches and process pages individually
- For text extraction: `pdftotext -bbox-layout` is fastest for plain text
- For image extraction: `pdfimages` is much faster than rendering pages
- For memory management: Process PDFs in chunks for very large files

## Common Issues

### Encrypted PDFs

```python
# Handle password-protected PDFs
from pypdf import PdfReader

try:
    reader = PdfReader("encrypted.pdf")
    if reader.is_encrypted:
        reader.decrypt("password")
except Exception as e:
    print(f"Failed to decrypt: {e}")
```

### Corrupted PDFs

```bash
# Use qpdf to repair
qpdf --check corrupted.pdf
qpdf --fix-qdf damaged.pdf repaired.pdf
```

### Text Extraction Issues

For scanned PDFs where text extraction returns "(cid:X)" patterns, use OCR:

```python
import pytesseract
from pdf2image import convert_from_path

def extract_text_with_ocr(pdf_path):
    images = convert_from_path(pdf_path)
    text = ""
    for i, image in enumerate(images):
        text += pytesseract.image_to_string(image)
    return text
```

### LibreOffice Not Installed

Install LibreOffice:
```bash
# Linux (Ubuntu/Debian)
sudo apt-get install libreoffice

# macOS
brew install --cask libreoffice
```

## Verification Commands

After completing your PDF work:

```bash
# Check for fillable fields
python scripts/check_fillable_fields.py document.pdf

# Extract text for verification
pdftotext document.pdf output.txt

# Verify filled form by converting to images
python scripts/convert_pdf_to_images.py filled.pdf verify/

# Validate bounding boxes before filling
python scripts/check_bounding_boxes.py fields.json
```
