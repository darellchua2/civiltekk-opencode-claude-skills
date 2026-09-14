---
name: zai-video-skill
description: >-
  Generate video from a text (or first-frame image) prompt via Z.AI CogVideoX-3
  — submit then poll the async result, save as local MP4. Triggers: video
  generation, generate video, text to video, image to video.
license: Apache-2.0
compatibility: opencode
category: Media Generation
---

## What I do

I provide the exact recipe for an agent to **generate a video** via the Z.AI
**CogVideoX-3** API and **save it to a local file**. Generation is **asynchronous**:
`POST /videos/generations` returns a task `id`, and the finished MP4 URL only appears
after polling `GET /async-result/{id}`. OpenCode's provider layer is chat-only, so this
endpoint is reachable only through direct HTTP calls.

## Why a skill (not a provider)

- OpenCode providers speak **chat completions** — they cannot hit `/videos/generations`
  or return binary files.
- Video tasks take minutes; the agent must **submit, then poll in the background**
  (PTY pattern below) instead of blocking the session in a synchronous loop.
- The result is a URL — a file must be downloaded and its path returned.

## Prerequisite — API key resolution

```bash
KEY="${ZAI_API_KEY:-$(jq -r '.["zai"].key // .["zai-coding-plan"].key // empty' \
     ~/.local/share/opencode/auth.json 2>/dev/null)}"
[ -z "$KEY" ] && { echo "ZAI_API_KEY not found — set it (export ZAI_API_KEY) or run \`opencode auth login\` (Z.AI)."; exit 1; }
```

If neither source has the key, **stop and report** — do not proceed.

## Recipe

### 1. Submit the task

```bash
# --- options ---
PROMPT="A slow dolly shot through a neon-lit city street at night, rain on asphalt"  # REQUIRED
IMAGE=""                                              # optional first-frame image URL or base64 (i2v)
DURATION="${DURATION:-5}"                             # 5 | 10 (seconds)
FPS="${FPS:-30}"                                      # 30 | 60
SIZE="${SIZE:-1920x1080}"                             # up to 4K; e.g. 1280x720, 1920x1080, 3840x2160
WITH_AUDIO="${WITH_AUDIO:-false}"                     # true adds generated audio track
BASE="${ZAI_MEDIA_ENDPOINT:-https://api.z.ai/api/paas/v4}"  # pay-as-you-go ONLY (not on the coding plan)

BODY=$(python3 -c 'import json,sys
b={"model":"cogvideox-3","prompt":sys.argv[1],"duration":int(sys.argv[2]),"fps":int(sys.argv[3]),"size":sys.argv[4],"with_audio":sys.argv[5]=="true"}
if sys.argv[6]: b["image_url"]=sys.argv[6]
print(json.dumps(b))' "$PROMPT" "$DURATION" "$FPS" "$SIZE" "$WITH_AUDIO" "$IMAGE")

RESP=$(curl -sS --max-time 60 -X POST "$BASE/videos/generations" \
  -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' -d "$BODY")

TASK_ID=$(printf '%s' "$RESP" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if d.get("error"):
    sys.stderr.write("API error: " + json.dumps(d["error"]) + "\n"); sys.exit(1)
print(d.get("id",""))') || { echo "Submit failed. Response: $RESP"; exit 1; }
[ -z "$TASK_ID" ] && { echo "No task id in response: $RESP"; exit 1; }
echo "SUBMITTED: $TASK_ID (billable ~\$0.20/video once it runs)"
```

### 2. Poll in the background (PTY pattern — do not block the session)

Video generation takes **minutes**. From the agent, spawn a PTY session
(`pty_spawn`, `notifyOnExit: true`) that polls and exits when done, then continue
other work and read the result when the exit notification arrives:

```bash
# runs inside the PTY; exits 0 only on SUCCESS
for i in $(seq 1 60); do                       # 60 x 15s = 15 min ceiling
  S=$(curl -sS --max-time 30 "$BASE/async-result/$TASK_ID" -H "Authorization: Bearer $KEY" \
      | python3 -c 'import sys,json; print(json.load(sys.stdin).get("task_status",""))')
  echo "poll $i: $S"
  [ "$S" = "SUCCESS" ] && exit 0
  [ "$S" = "FAIL" ] && { echo "task failed"; exit 1; }
  sleep 15
done
echo "timeout"; exit 1
```

No PTY plugin (plain bash)? Fall back to a foreground loop with the same body —
just tell the caller it blocks.

### 3. Download and verify

```bash
OUT="${OUT:-./cogvideox-$TASK_ID.mp4}"
URL=$(curl -sS --max-time 30 "$BASE/async-result/$TASK_ID" -H "Authorization: Bearer $KEY" | python3 -c '
import sys, json
d = json.load(sys.stdin)
u = d.get("video_result") or d.get("video_url") or []
if isinstance(u, list): u = u[0].get("url","") if u else ""
print(u or "")')
[ -z "$URL" ] && { echo "No video URL for $TASK_ID"; exit 1; }
curl -L -sS --max-time 600 -o "$OUT" "$URL" || { echo "Download failed for $URL"; exit 1; }
file "$OUT" | grep -qiE 'video|mp4|iso media' && echo "SAVED: $OUT ($(wc -c <"$OUT") bytes)" \
  || { echo "Downloaded file is not a video: $(file "$OUT")"; exit 1; }
```

**Output:** the task id (`SUBMITTED: <id>`) then the saved file path (`SAVED: <path>`).

## Error handling

| Condition | Detect | Action |
|-----------|--------|--------|
| Missing key | `[ -z "$KEY" ]` | Stop; tell caller to set `ZAI_API_KEY` |
| API error (auth/quota/content) | response JSON has `"error"` | Print error body; report `Status: failed` |
| Task FAIL | `task_status: FAIL` | Surface the task id + error; suggest rephrasing prompt |
| Timeout | 15 min of polls | Report task id — it may still finish; poll again later |
| Download fails / non-video | curl exit ≠ 0 or `file` wrong | Report the URL + failure |
| Rate limited | HTTP 429 | Wait and retry once; otherwise report |

## Cost & compliance note

CogVideoX-3 is **pay-as-you-go** (~$0.20/video), **not** covered by the GLM Coding
Plan — the recipe deliberately targets `/api/paas/v4`. Always announce the billable
cost before submitting.

## Caller contract

After running the recipe, return the **saved file path** (the `SAVED: <path>` line).
Do not echo API response JSON. If submit, poll, or download failed, return
`Status: failed` with the error message and the task id (if one exists), and stop.
