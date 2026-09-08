#!/usr/bin/env bash
# LOCAL M5 LIVE-SESSION CHECK — not a CI gate.
#
# Runs the workflow-explore prompt battery against a live Claude Code install
# and records falsifiable delegation and false-trigger rates. It needs model
# access, a project where the Claude instructions and skills are deployed, and
# a Claude configuration that permits the Skill and specialist-agent calls.
# Run it with the host Claude environment; do not wrap it in `nix develop`,
# because enterprise Claude setups may invoke host-only auth helpers.
#
# Usage:
#   verification/check-workflow-explore.sh /path/to/target-repo [output-dir]
#
# A non-trivial prompt delegates only when its event stream contains evidence
# of loading workflow-explore, delegating to explore, and reaching both plan
# and spar. A trivial prompt false-triggers when it contains that same complete
# orchestration signature. The accepted bar is defined in the fixture file.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$REPO_ROOT/verification/workflow-explore-prompts.json"
TARGET_REPO="${1:?usage: $0 /path/to/target-repo [output-dir]}"
OUTPUT_DIR="${2:-$REPO_ROOT/verification/results/$(date +%Y%m%d-%H%M%S)}"

command -v claude >/dev/null || { echo "error: claude CLI is required" >&2; exit 2; }
command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 2; }
[[ -d "$TARGET_REPO" ]] || { echo "error: target repo does not exist: $TARGET_REPO" >&2; exit 2; }
[[ -f "$FIXTURES" ]] || { echo "error: fixtures not found: $FIXTURES" >&2; exit 2; }

mkdir -p "$OUTPUT_DIR"

contains_orchestration_trace() {
  local events="$1"
  [[ "$(jq -se '
    [ .[] | .. | objects | select(.type? == "tool_use")
      | {name: (.name? // ""), input: (.input? // {})} ] as $calls
    | ([ $calls[] | (.name + " " + (.input | tojson)) | ascii_downcase | contains("workflow-explore") ] | any)
      and ([ $calls[] | (.input | tojson | ascii_downcase | contains("explore")) ] | any)
      and ([ $calls[] | (.input | tojson | ascii_downcase | contains("plan")) ] | any)
      and ([ $calls[] | (.input | tojson | ascii_downcase | contains("spar")) ] | any)
  ' "$events")" == true ]]
}

total_non_trivial=0
delegated_non_trivial=0
total_trivial=0
false_triggered_trivial=0
failed_runs=0

while IFS= read -r test_case; do
  id="$(jq -r '.id' <<<"$test_case")"
  kind="$(jq -r '.kind' <<<"$test_case")"
  prompt="$(jq -r '.prompt' <<<"$test_case")"
  events="$OUTPUT_DIR/$id.stream.jsonl"

  echo "==> $id ($kind)"
  if [[ "$kind" == "non-trivial" ]]; then
    ((total_non_trivial += 1))
  else
    ((total_trivial += 1))
  fi

  # Stream JSON retains tool-use events, unlike the default text output. Do
  # not bypass permissions: a denied skill/agent call is a real failure of the
  # hands-off workflow and must count against delegation.
  if ! (
    cd "$TARGET_REPO"
    claude --print --verbose --output-format stream-json --forward-subagent-text \
      --permission-mode auto --permission-prompts none "$prompt"
  ) > "$events"; then
    echo "error: Claude invocation failed for $id; see $events" >&2
    printf '%s\t%s\terror\n' "$id" "$kind" | tee -a "$OUTPUT_DIR/results.tsv"
    ((failed_runs += 1))
    continue
  fi

  if contains_orchestration_trace "$events"; then
    trace=yes
  else
    trace=no
  fi
  printf '%s\t%s\t%s\n' "$id" "$kind" "$trace" | tee -a "$OUTPUT_DIR/results.tsv"

  if [[ "$kind" == "non-trivial" ]]; then
    if [[ "$trace" == yes ]]; then
      ((delegated_non_trivial += 1))
    fi
  else
    if [[ "$trace" == yes ]]; then
      ((false_triggered_trivial += 1))
    fi
  fi
done < <(jq -c '.prompts[]' "$FIXTURES")

delegation_rate="$(jq -n "if $total_non_trivial == 0 then null else $delegated_non_trivial / $total_non_trivial end")"
false_trigger_rate="$(jq -n "if $total_trivial == 0 then null else $false_triggered_trivial / $total_trivial end")"
minimum_delegation="$(jq -r '.passBar.minimumDelegationRate' "$FIXTURES")"
maximum_false_trigger="$(jq -r '.passBar.maximumFalseTriggerRate' "$FIXTURES")"

jq -n \
  --argjson delegationRate "$delegation_rate" \
  --argjson falseTriggerRate "$false_trigger_rate" \
  --argjson failedRuns "$failed_runs" \
  --argjson minimumDelegationRate "$minimum_delegation" \
  --argjson maximumFalseTriggerRate "$maximum_false_trigger" \
  --arg outputDir "$OUTPUT_DIR" \
  '{delegationRate: $delegationRate, falseTriggerRate: $falseTriggerRate, failedRuns: $failedRuns,
    pass: ($failedRuns == 0 and $delegationRate != null and $falseTriggerRate != null
      and $delegationRate >= $minimumDelegationRate and $falseTriggerRate <= $maximumFalseTriggerRate),
    passBar: {minimumDelegationRate: $minimumDelegationRate, maximumFalseTriggerRate: $maximumFalseTriggerRate},
    outputDir: $outputDir}' | tee "$OUTPUT_DIR/summary.json"
