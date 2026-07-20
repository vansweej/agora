#!/usr/bin/env bash
# renderers/render.sh — drives the OpenCode -> Claude renderer over the
# shared-15 skills and the 6 persona agents, producing Claude-format skills
# under build/clients/claude/skills/<name>/SKILL.md.
#
# Uses `opencode run` headless with a dedicated, tools-disabled primary
# agent (.opencode/agent/renderer.md) so the renderer can never write files,
# run shell commands, or fetch the web — only emit text. The renderer prompt
# itself (renderers/opencode-to-claude.md) is the single source of truth,
# passed in the message rather than duplicated into the agent.
#
# Output is CI-only / not committed (build/ is gitignored). Idempotent: the
# output directory is wiped before each run.
#
# Usage: renderers/render.sh [--attach http://localhost:PORT]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="$REPO_ROOT/renderers/opencode-to-claude.md"
OUT_DIR="$REPO_ROOT/build/clients/claude/skills"
MODEL="github-copilot/claude-opus-4.8"
AGENT="renderer"

ATTACH_ARGS=()
if [[ "${1:-}" == "--attach" ]]; then
  ATTACH_ARGS=(--attach "$2")
fi

SHARED_SKILLS=(
  analyst architect cpp debugger documenter explorer go haskell julia
  programmer python reviewer rust tester typescript
)
PERSONA_AGENTS=(brainstorm spar teach plan explore build)

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "error: renderer prompt not found at $PROMPT_FILE" >&2
  exit 1
fi

echo "==> Wiping $OUT_DIR for idempotent render"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

PROMPT_TEXT="$(cat "$PROMPT_FILE")"
FAILED=0

render_one() {
  local source_path="$1"
  local out_name="$2"
  local out_path="$OUT_DIR/$out_name/SKILL.md"
  local raw_json
  local text

  echo "==> Rendering $source_path -> $out_path"
  mkdir -p "$(dirname "$out_path")"

  raw_json="$(cd "$REPO_ROOT" && opencode run \
    "$PROMPT_TEXT

SOURCE PATH: $source_path" \
    --pure --dir . --agent "$AGENT" \
    --model "$MODEL" --format json \
    --file="$source_path" \
    "${ATTACH_ARGS[@]}")"

  text="$(printf '%s\n' "$raw_json" | python3 -c '
import json, sys
last = None
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    obj = json.loads(line)
    if obj.get("type") == "text":
        last = obj["part"]["text"]
if last is None:
    sys.exit(2)
print(last)
')"

  if [[ -z "$text" ]]; then
    echo "!! render failed (no text output) for $source_path" >&2
    FAILED=1
    return
  fi

  if grep -q '^RENDER-ERROR:' <<<"$text"; then
    echo "!! RENDER-ERROR for $source_path:" >&2
    grep '^RENDER-ERROR:' <<<"$text" >&2
    FAILED=1
    return
  fi

  printf '%s\n' "$text" > "$out_path"
}

for name in "${SHARED_SKILLS[@]}"; do
  render_one "skills/$name/SKILL.md" "$name"
done

for name in "${PERSONA_AGENTS[@]}"; do
  render_one "agents/$name.md" "$name"
done

if [[ "$FAILED" -ne 0 ]]; then
  echo "==> render.sh completed WITH FAILURES" >&2
  exit 1
fi

echo "==> render.sh completed: $(find "$OUT_DIR" -name SKILL.md | wc -l | tr -d ' ') files written to $OUT_DIR"
