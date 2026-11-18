#!/usr/bin/env bash
# renderers/render.sh — drives the OpenCode -> Claude renderer over the
# shared-15 skills, the 3 manual persona agents, and the coordinator +
# specialist subagents, producing Claude-format output under
# clients/claude/.apm/skills/<name>/SKILL.md (skills, personas, coordinator)
# and clients/claude/.apm/agents/<name>.md (explore/spar/plan subagents).
#
# Uses `opencode run` headless with a dedicated, tools-disabled primary
# agent (.opencode/agent/renderer.md) so the renderer can never write files,
# run shell commands, or fetch the web — only emit text. The renderer prompt
# itself (renderers/opencode-to-claude.md) is the single source of truth,
# passed in the message rather than duplicated into the agent.
#
# Output IS COMMITTED (Option A): clients/claude/.apm/{skills,agents}/ are
# authored-once, rendered-and-committed generated source, marked with a
# DO-NOT-EDIT header per file (see renderers/opencode-to-claude.md). This is a
# manual, on-demand, local step — run it (inside `nix develop`, so
# sha256sum/coreutils are guaranteed present) whenever a shared skill, agent,
# or the renderer prompt itself changes, then commit the result.
# `checks.claude-render-fresh` in flake.nix is the pure (no-LLM) safety net
# that fails `nix flake check` if the committed tree drifts out of sync with
# its sources.
#
# Idempotent: only the GENERATED skill/agent subdirectories/files (below) are
# wiped before each run — the two hand-authored native skills (grill-me,
# grill-with-docs) that live alongside in clients/claude/.apm/skills/ are
# untouched.
#
# Usage: renderers/render.sh [--server http://localhost:PORT]
#        renderers/render.sh --check-models
#
# --check-models only verifies that every rendered agent's `model:` value is
# listed in the Model map of renderers/opencode-to-claude.md, prints
# "model map OK" and exits 0 (no wipe, no LLM calls). A normal render runs
# the same check first and exits 1 before wiping anything if it fails.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="$REPO_ROOT/renderers/opencode-to-claude.md"
SKILLS_OUT_DIR="$REPO_ROOT/clients/claude/.apm/skills"
AGENTS_OUT_DIR="$REPO_ROOT/clients/claude/.apm/agents"
MANIFEST="$REPO_ROOT/clients/claude/.apm/manifest.json"
MODEL="github-copilot/claude-opus-5.5"
AGENT="renderer"

SERVER_ARGS=()
CHECK_ONLY=0
if [[ "${1:-}" == "--server" || "${1:-}" == "--attach" ]]; then
  SERVER_ARGS=(--server "$2")
elif [[ "${1:-}" == "--check-models" ]]; then
  CHECK_ONLY=1
fi

SHARED_SKILLS=(
  analyst architect cpp debugger documenter explorer go haskell julia
  programmer python rails reviewer ruby rust tester typescript
)
PERSONA_SKILLS=(brainstorm teach build)
SPECIALIST_SUBAGENTS=(explore spar plan)
COORDINATOR=coordinator

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "error: renderer prompt not found at $PROMPT_FILE" >&2
  exit 1
fi

# Fail fast, before any wipe or LLM call, if an agent's `model:` is not in
# the Model map (otherwise the renderer emits RENDER-ERROR mid-run).
# Reports every unmapped file, then exits 1.
check_model_map() {
  local map_section
  local src
  local model
  local bad=0
  map_section="$(sed -n '/^### Model map$/,/^If you encounter any other value/p' "$PROMPT_FILE")"
  for name in "${PERSONA_SKILLS[@]}" "${SPECIALIST_SUBAGENTS[@]}" "$COORDINATOR"; do
    src="$REPO_ROOT/.apm/agents/$name.agent.md"
    if [[ ! -f "$src" ]]; then
      echo "error: MODEL-MAP: agent source not found: $src" >&2
      bad=1
      continue
    fi
    model="$(sed -n 's/^model:[[:space:]]*//p' "$src")"
    if [[ -z "$model" ]]; then
      echo "error: MODEL-MAP: no model: line in $src" >&2
      bad=1
    elif ! grep -qF "| \`$model\`" <<<"$map_section"; then
      echo "error: MODEL-MAP: $src uses model '$model', which is not in the Model map of $PROMPT_FILE" >&2
      bad=1
    fi
  done
  if [[ "$bad" -ne 0 ]]; then
    echo "error: MODEL-MAP: add the missing model(s) to the '### Model map' table, then re-run" >&2
    exit 1
  fi
}

check_model_map
if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo "model map OK"
  exit 0
fi

echo "==> Wiping generated skill subdirectories in $SKILLS_OUT_DIR for idempotent render"
for name in "${SHARED_SKILLS[@]}" "${PERSONA_SKILLS[@]}"; do
  rm -rf "$SKILLS_OUT_DIR/$name"
done
rm -rf "$SKILLS_OUT_DIR/workflow-explore"
# Defensive: explore/spar/plan used to render as skills (pre-coordinator
# architecture); wipe any stale leftovers from that layout so a partial
# revert never leaves an orphaned skill dir alongside the new agent file.
for name in "${SPECIALIST_SUBAGENTS[@]}"; do
  rm -rf "$SKILLS_OUT_DIR/$name"
done
mkdir -p "$SKILLS_OUT_DIR"

echo "==> Wiping generated agent files in $AGENTS_OUT_DIR for idempotent render"
for name in "${SPECIALIST_SUBAGENTS[@]}"; do
  rm -f "$AGENTS_OUT_DIR/$name.md"
done
mkdir -p "$AGENTS_OUT_DIR"

PROMPT_TEXT="$(cat "$PROMPT_FILE")"
FAILED=0

render_to_skill() {
  local source_path="$1"
  local out_name="$2"
  local out_path="$SKILLS_OUT_DIR/$out_name/SKILL.md"
  render_common "$source_path" "$out_path"
}

render_to_agent() {
  local source_path="$1"
  local out_name="$2"
  local out_path="$AGENTS_OUT_DIR/$out_name.md"
  render_common "$source_path" "$out_path"
}

render_common() {
  local source_path="$1"
  local out_path="$2"
  local raw_json
  local text

  echo "==> Rendering $source_path -> $out_path"
  mkdir -p "$(dirname "$out_path")"

  raw_json="$(cd "$REPO_ROOT" && opencode run \
    "$PROMPT_TEXT

SOURCE PATH: $source_path" \
    --agent "$AGENT" \
    --model "$MODEL" --format json \
    --file="$source_path" \
    "${SERVER_ARGS[@]}")"

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
  render_to_skill ".apm/skills/$name/SKILL.md" "$name"
done

for name in "${PERSONA_SKILLS[@]}"; do
  render_to_skill ".apm/agents/$name.agent.md" "$name"
done

for name in "${SPECIALIST_SUBAGENTS[@]}"; do
  render_to_agent ".apm/agents/$name.agent.md" "$name"
done

render_to_skill ".apm/agents/coordinator.agent.md" "workflow-explore"

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
  for name in "${SHARED_SKILLS[@]}"; do emit ".apm/skills/$name/SKILL.md"; done
  for name in "${PERSONA_SKILLS[@]}"; do emit ".apm/agents/$name.agent.md"; done
  for name in "${SPECIALIST_SUBAGENTS[@]}"; do emit ".apm/agents/$name.agent.md"; done
  emit ".apm/agents/coordinator.agent.md"
  printf '\n}\n'
} > "$MANIFEST"

n_skills=$(find "$SKILLS_OUT_DIR" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
n_agents=$(find "$AGENTS_OUT_DIR" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
echo "==> render.sh completed: $n_skills skill files + $n_agents agent files written"
