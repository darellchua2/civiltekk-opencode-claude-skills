---
name: zai-image-generation-skill
description: >-
  Generate images from text prompts via Z.AI GLM-Image API, saved as local PNGs
  — direct /images/generations call. Triggers: image generation, generate image,
  text to image, draw a picture.
license: Apache-2.0
compatibility: opencode
category: Media Generation
---

## What I do

I provide the exact recipe for an agent to **generate an image from a text prompt** via the Z.AI
**GLM-Image** API and **save it to a local file**. OpenCode's provider layer is chat-only, so image
generation (a separate `/images/generations` endpoint) is reachable only through a direct HTTP call.
The API returns a **temporary URL** (expires in ~30 days) on `mfile.z.ai`, so the recipe always
**downloads the result to a persistent file** on disk.

## Why a skill (not a provider)

- OpenCode providers (`@ai-sdk/openai-compatible`) speak **chat completions** — they cannot hit the
  `/images/generations` endpoint or return binary files.
- GLM-Image is a dedicated generation model (`glm-image`, `cogview-4-250304`), separate from the
  chat/vision lineup. Calling it requires a targeted `POST {base}/images/generations`.
- The result is a URL, not text — a file must be produced and its path returned to the caller.

## Prerequisite — API key resolution

The recipe resolves the key robustly (env first, then opencode's credential store):

```bash
KEY="${ZAI_API_KEY:-$(jq -r '.["zai-coding-plan"].key // .["zai"].key // empty' \
     ~/.local/share/opencode/auth.json 2>/dev/null)}"
[ -z "$KEY" ] && { echo "ZAI_API_KEY not found — set it (export ZAI_API_KEY=...) or run \`opencode auth login\` (Z.AI)."; exit 1; }
```

If neither source has the key, **stop and report** — do not proceed.

## Recipe

Set the options, then run generate → extract URL → download → verify:

```bash
# --- options ---
PROMPT="A cute kitten on a sunny windowsill, blue sky and white clouds"  # REQUIRED
OUT="${OUT:-./glm-image-$(date +%s).png}"          # output path (default: ./glm-image-<ts>.png)
SIZE="${SIZE:-1280x1280}"                           # glm-image: 1280x1280 | 1568x1056 | 1056x1568 | 1472x1088 | 1088x1472 | 1728x960 | 960x1728
QUALITY="${QUALITY:-standard}"                      # standard (~5-10s) | hd (~20s, richer detail)
MODEL="${MODEL:-glm-image}"                         # glm-image (default) | cogview-4-250304
ENDPOINT="${ZAI_IMAGE_ENDPOINT:-https://api.z.ai/api/coding/paas/v4}"  # coding plan (subscription). Alt: https://api.z.ai/api/paas/v4 (pay-as-you-go)

# --- 1. generate ---
RESP=$(curl -sS --max-time 180 -X POST "$ENDPOINT/images/generations" \
  -H "Authorization: Bearer $KEY" \
  -H 'Content-Type: application/json' \
  -d "$(python3 -c 'import json,sys
print(json.dumps({"model":sys.argv[1],"prompt":sys.argv[2],"size":sys.argv[3],"quality":sys.argv[4]}))' \
      "$MODEL" "$PROMPT" "$SIZE" "$QUALITY")")

# --- 2. extract URL (or surface the error) ---
URL=$(printf '%s' "$RESP" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if d.get("error"):
    sys.stderr.write("API error: " + json.dumps(d["error"]) + "\n"); sys.exit(1)
print(d.get("data",[{}])[0].get("url",""))') || { echo "Generation failed. Response: $RESP"; exit 1; }
[ -z "$URL" ] && { echo "No image URL in response: $RESP"; exit 1; }

# --- 3. download to file (follow redirects; URL contains '?') ---
curl -L -sS --max-time 120 -o "$OUT" "$URL" || { echo "Download failed for $URL"; exit 1; }

# --- 4. verify it's a real image ---
file "$OUT" | grep -qiE 'image|png|jpeg' && echo "SAVED: $OUT ($(wc -c <"$OUT") bytes)" \
  || { echo "Downloaded file is not an image: $(file "$OUT")"; exit 1; }
```

**Output:** the saved file path (e.g. `SAVED: ./glm-image-1786024489.png`).

### Options

| Var        | Default                              | Values                                                                                          |
| ---------- | ------------------------------------ | ----------------------------------------------------------------------------------------------- |
| `PROMPT`   | *(required)*                         | Text description of the desired image                                                           |
| `OUT`      | `./glm-image-<timestamp>.png`        | Any writable path (extension reflects format — GLM-Image returns PNG)                            |
| `SIZE`     | `1280x1280`                          | `glm-image`: 1280x1280, 1568x1056, 1056x1568, 1472x1088, 1088x1472, 1728x960, 960x1728 (1024–2048px, ÷32) |
| `QUALITY`  | `standard`                           | `standard` (fast) \| `hd` (richer, ~20s)                                                         |
| `MODEL`    | `glm-image`                          | `glm-image` \| `cogview-4-250304` (cogview uses different size rules: 1024x1024 base)            |
| `ENDPOINT` | coding plan (`/api/coding/paas/v4`)  | Override via `$ZAI_IMAGE_ENDPOINT`; pay-as-you-go = `https://api.z.ai/api/paas/v4`              |

## Error handling

| Condition                       | Detect                                       | Action                                                                              |
| ------------------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------- |
| Missing key                     | `[ -z "$KEY" ]`                              | Stop; tell caller to set `ZAI_API_KEY` or `opencode auth login` (Z.AI)              |
| API error (auth/quota/content)  | response JSON has `"error"`                  | Print error body + code; report `Status: failed`                                    |
| Content filtered                | error code for safety rejection              | Rephrase the prompt; do not retry identical prompt                                  |
| No URL in response              | `$URL` empty                                 | Dump response; report failure                                                       |
| Download fails / non-image      | curl exit ≠ 0 or `file` not an image         | Report the URL + failure; note `mfile.z.ai` must be reachable (some sandboxes block it) |
| Rate limited (429)              | HTTP 429                                     | Wait and retry once; otherwise report                                              |

## Reachability note

The generated image is hosted on **`mfile.z.ai`**. Confirm it is reachable from the execution
environment (`curl -sI https://mfile.z.ai`). Some sandboxes/CI blackhole it (resolves to `0.0.0.0`),
which breaks the download step even though generation succeeds. On the user's machine it is normally
reachable.

## Compliance note

GLM-Image is a **separate pay-as-you-go product** ($/image), outside the GLM Coding Plan's
documented scope ("AI-powered coding"). It is *reachable* on the coding endpoint (the default above)
but heavy/out-of-scope generation can attract risk-control action per the
[Usage Policy](https://docs.z.ai/devpack/usage-policy). For reliable, in-policy image generation,
set `ZAI_IMAGE_ENDPOINT=https://api.z.ai/api/paas/v4` against a standard pay-as-you-go key.

## Caller contract

After running the recipe, return the **saved file path** (the `SAVED: <path>` line) to the calling
agent. Do not echo the API response JSON or the temporary `mfile.z.ai` URL. If generation or
download failed, return `Status: failed` with the error message and stop.
