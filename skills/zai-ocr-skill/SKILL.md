---
name: zai-ocr-skill
description: >-
  Extract text and layout from images or PDFs via the Z.AI GLM-OCR
  layout_parsing API — structured, layout-aware OCR. Triggers: OCR, extract
  text from image, layout parsing, document text extraction.
license: Apache-2.0
compatibility: opencode
category: Media Generation
---

## What I do

I provide the exact recipe for an agent to **extract text with layout structure**
from an image or PDF via the Z.AI **GLM-OCR** `layout_parsing` API. Unlike a
vision-chat description, the dedicated endpoint returns the document's text
organized by detected layout (blocks, reading order, tables).

## Why a skill (not vision chat)

- `POST /layout_parsing` is a dedicated document-extraction endpoint — richer and
  more faithful for dense/structured documents than asking a chat model to describe an image.
- Input is an **http(s) URL**. Base64 is documented in the API schema but every
  base64 form is rejected server-side with code `1214` (verified 2026-08-30:
  png/jpeg/pdf × raw/data-URI/padded/unpadded) — local files use the vision
  fallback in Path B.

## Prerequisite — API key resolution

```bash
KEY="${ZAI_API_KEY:-$(jq -r '.["zai"].key // .["zai-coding-plan"].key // empty' \
     ~/.local/share/opencode/auth.json 2>/dev/null)}"
[ -z "$KEY" ] && { echo "ZAI_API_KEY not found — set it (export ZAI_API_KEY) or run \`opencode auth login\` (Z.AI)."; exit 1; }
```

If neither source has the key, **stop and report** — do not proceed.

## Recipe

### Path A — file already has a public URL (full layout result)

```bash
FILE_URL="https://example.com/document.png"           # REQUIRED — public http(s) URL, png/jpg/pdf
BASE="${ZAI_MEDIA_ENDPOINT:-https://api.z.ai/api/paas/v4}"  # pay-as-you-go ONLY

RESP=$(curl -sS --max-time 180 -X POST "$BASE/layout_parsing" \
  -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
  -d "{\"model\":\"glm-ocr\",\"file\":\"$FILE_URL\"}")

printf '%s' "$RESP" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if d.get("error"):
    sys.stderr.write("API error: " + json.dumps(d["error"]) + "\n"); sys.exit(1)
print(d.get("md_results") or "(empty md_results)")
for page in d.get("layout_details", []):
    for el in page:
        print("[" + str(el.get("label", "")) + "] " + str(el.get("content", "")))'
```

**Output:** `md_results` (markdown of the whole document) plus one
`[label] content` line per layout element (text/table/formula/image) on stdout.

### Path B — local file (text extraction via glm-5.3-flash vision)

```bash
# ponytail: layout_parsing rejects base64 server-side (code 1214, all variants
# tested 2026-08-30); vision chat covers local files — retry layout_parsing b64
# on a future API rev. Full layout structure for a local file needs a public URL.
FILE="path/to/image.png"                              # png/jpg, image-input limit ≤5 MB
MIME="image/png"
BASE="${ZAI_MEDIA_ENDPOINT:-https://api.z.ai/api/paas/v4}"  # pay-as-you-go ONLY

B64=$(base64 -w0 "$FILE")
RESP=$(curl -sS --max-time 180 -X POST "$BASE/chat/completions" \
  -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
  -d "$(python3 -c 'import json,sys
print(json.dumps({"model":"glm-5.3-flash","messages":[{"role":"user","content":[
  {"type":"image_url","image_url":{"url":"data:"+sys.argv[1]+";base64,"+sys.argv[2]}},
  {"type":"text","text":"Extract ALL text verbatim, preserving reading order; render tables as markdown."}]}]}))' \
      "$MIME" "$B64")")

printf '%s' "$RESP" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if d.get("error"):
    sys.stderr.write("API error: " + json.dumps(d["error"]) + "\n"); sys.exit(1)
print(d["choices"][0]["message"]["content"])'
```

**Output:** extracted text (verbatim markdown) on stdout. No bbox/label
structure — host the file at a public URL and use Path A when layout
coordinates matter.

## Error handling

| Condition | Detect | Action |
|-----------|--------|--------|
| Missing key | `[ -z "$KEY" ]` | Stop; tell caller to set `ZAI_API_KEY` |
| Code `1214` "only supports PDF, JPG, PNG, JPEG" | response `error.code == "1214"` | Base64 was passed or URL unreachable — switch to Path A with a public URL, or Path B for local files |
| File too large | API size error | Split PDF pages (`pdftk`/`qpdf`) and call per batch |
| API error (auth/quota/format) | response JSON has `"error"` | Print error body; report `Status: failed` |
| Unexpected response shape | no `md_results`/`layout_details` key | Print raw JSON (recipe does) — do not guess |
| Rate limited | HTTP 429 | Wait and retry once; otherwise report |

## Cost note

Both paths are **pay-as-you-go** and **not** covered by the GLM Coding Plan —
the recipes target `/api/paas/v4` (Path A: GLM-OCR per-token; Path B:
glm-5.3-flash vision per-token).

## Caller contract

After running the recipe, return the **extracted content** (stdout). Do not echo the
full API response JSON or the base64 payload. If OCR failed, return `Status: failed`
with the error message and stop.
