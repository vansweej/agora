#!/usr/bin/env bash
# renderers/render.sh — drives the OpenCode -> Claude renderer over the
# shared-15 skills and the 6 persona agents, producing Claude-format skills
# under clients/claude/generated/skills/<name>/SKILL.md.
#
# Uses `opencode run` headless with a dedicated, tools-disabled primary
# agent (.opencode/agent/renderer.md) so the renderer can never write files,
# run shell commands, or fetch the web — only emit text. The renderer prompt
# itself (renderers/opencode-to-claude.md) is the single source of truth,
# passed in the message rather than duplicated into the agent.
#
# Output IS COMMITTED (Option A): clients/claude/generated/ is authored-once,
# rendered-and-committed generated source, marked with a DO-NOT-EDIT header
# per file (see renderers/opencode-to-claude.md). This is a manual, on-demand,
# local step — run it (inside `nix develop`, so sha256sum/coreutils are
# guaranteed present) whenever a shared skill, persona agent, or the renderer
# prompt itself changes, then commit the result. `checks.claude-render-fresh`
# in flake.nix is the pure (no-LLM) safety net that fails `nix flake check`
# if the committed tree drifts out of sync with its sources.
#
# Idempotent: the output directory is wiped before each run.
#
# Usage: renderers/render.sh [--attach http://localhost:PORT]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="$REPO_ROOT/renderers/opencode-to-claude.md"
OUT_DIR="$REPO_ROOT/clients/claude/generated/skills"
MANIFEST="$REPO_ROOT/clients/claude/generated/manifest.json"
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

  # Extract .part.text from the LAST {"type":"text",...} JSONL event via jq
  # (not python3: macOS's /usr/bin/python3 xcrun-stub fails to resolve inside
  # `nix develop`, since the clang toolchain's DEVELOPER_DIR points at a Nix
  # store path). jq handles concatenated JSON docs natively with -s (slurp).
  text="$(printf '%s\n' "$raw_json" | jq -s -r '
    [.[] | select(.type == "text")]
    | if length == 0 then empty else (last | .part.text) end
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

# ── Emit provenance manifest ────────────────────────────────────────────────
# Maps each authored SOURCE path -> sha256 of its current on-disk content, so
# a later PURE flake check (checks.claude-render-fresh) can recompute these
# and fail if any source — or the renderer prompt itself — changed since this
# render, WITHOUT needing the LLM/network/creds in the check. The renderer
# prompt is included: changing the transform rules should force a re-render
# just like changing a source file.
echo "==> Writing $MANIFEST"
{
  printf '{\n'
  first=1
  emit() {
    local rel="$1"
    local h
    h="$(cd "$REPO_ROOT" && sha256sum "$rel" | cut -d' ' -f1)"
    if [[ $first -eq 0 ]]; then printf ',\n'; fi
    printf '  "%s": "%s"' "$rel" "$h"
    first=0
  }
  emit "renderers/opencode-to-claude.md"
  for name in "${SHARED_SKILLS[@]}"; do emit "skills/$name/SKILL.md"; done
  for name in "${PERSONA_AGENTS[@]}"; do emit "agents/$name.md"; done
  printf '\n}\n'
} > "$MANIFEST"

echo "==> render.sh completed: $(find "$OUT_DIR" -name SKILL.md | wc -l | tr -d ' ') files written to $OUT_DIR"
