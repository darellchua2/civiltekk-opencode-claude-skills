---
name: zai-asr-skill
description: >-
  Transcribe audio files to text via the Z.AI GLM-ASR API — POST
  /audio/transcriptions with a wav/mp3 (≤25MB, ≤30s). Triggers: transcribe,
  speech to text, ASR, audio transcription.
license: Apache-2.0
compatibility: opencode
category: Media Generation
---

## What I do

I provide the exact recipe for an agent to **transcribe an audio file** via the Z.AI
**GLM-ASR** API and return the **transcript text**. OpenCode has no voice-input path,
so transcription happens as a file-based tool call: `POST /audio/transcriptions`.

## Constraints (hard limits — check before calling)

- Models: `glm-asr-2512`
- File: **≤ 25 MB**, **≤ 30 seconds**, `.wav` or `.mp3`
- Longer audio must be split first (e.g. `ffmpeg -f segment -segment_times <n>`) —
  transcribe the segments in order and concatenate.

## Prerequisite — API key resolution

```bash
KEY="${ZAI_API_KEY:-$(jq -r '.["zai"].key // .["zai-coding-plan"].key // empty' \
     ~/.local/share/opencode/auth.json 2>/dev/null)}"
[ -z "$KEY" ] && { echo "ZAI_API_KEY not found — set it (export ZAI_API_KEY) or run \`opencode auth login\` (Z.AI)."; exit 1; }
```

If neither source has the key, **stop and report** — do not proceed.

## Recipe

```bash
# --- options ---
FILE="path/to/audio.mp3"                              # REQUIRED — .wav or .mp3, ≤25MB, ≤30s
BASE="${ZAI_MEDIA_ENDPOINT:-https://api.z.ai/api/paas/v4}"  # pay-as-you-go ONLY

# pre-flight: size + duration guards
[ -f "$FILE" ] || { echo "No such file: $FILE"; exit 1; }
[ "$(wc -c <"$FILE")" -le 26214400 ] || { echo "File >25MB — split it first"; exit 1; }

RESP=$(curl -sS --max-time 120 -X POST "$BASE/audio/transcriptions" \
  -H "Authorization: Bearer $KEY" \
  -F "model=glm-asr-2512" \
  -F "file=@$FILE")

TEXT=$(printf '%s' "$RESP" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if d.get("error"):
    sys.stderr.write("API error: " + json.dumps(d["error"]) + "\n"); sys.exit(1)
print(d.get("text",""))') || { echo "Transcription failed. Response: $RESP"; exit 1; }
echo "TRANSCRIPT: $TEXT"
```

**Output:** the transcript on the `TRANSCRIPT:` line.

## Error handling

| Condition | Detect | Action |
|-----------|--------|--------|
| Missing key | `[ -z "$KEY" ]` | Stop; tell caller to set `ZAI_API_KEY` |
| File too large / long | pre-flight check | Split with ffmpeg; transcribe segments; concatenate |
| Wrong format | file extension not wav/mp3 | Convert: `ffmpeg -i in -ar 16000 out.wav` |
| API error (auth/quota/format) | response JSON has `"error"` | Print error body; report `Status: failed` |
| Empty transcript | `text` empty | File may be silent — report, don't retry |
| Rate limited | HTTP 429 | Wait and retry once; otherwise report |

## Cost note

GLM-ASR is **pay-as-you-go** (~$0.03/MTok), **not** covered by the GLM Coding Plan —
the recipe targets `/api/paas/v4`.

## Caller contract

After running the recipe, return the **transcript text** (the `TRANSCRIPT:` line).
Do not echo API response JSON. If transcription failed, return `Status: failed`
with the error message and stop.
