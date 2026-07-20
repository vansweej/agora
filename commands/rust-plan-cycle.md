---
description: Execute a pre-written Rust plan unattended (plan → implement → fmt → clippy → test → coverage). Usage: /rust-plan-cycle <workspace> [--plan <file> | --input "..."] [--max-retries <int>] [--profile <name>]
---
Execute a Rust plan at the given workspace: $ARGUMENTS

Run the rust-plan-cycle pipeline and report the result:
!`bun run --cwd $AI_CODING_MONOREPO pipeline rust-plan-cycle $ARGUMENTS 2>&1`

Report each phase's outcome. If the pipeline failed, explain which phase failed and why. Note: rust-plan-cycle requires a feature branch (not main/master/develop), and either a plan file (--plan) or input text (--input). Exit code 2 means resumable failure (can re-run); exit code 3 means environment/input error (check branch, plan file, or input).
