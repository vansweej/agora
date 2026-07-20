---
description: Run any pipeline by name. Usage: /pipeline <name> <workspace> [--input "..."]
---
Run the pipeline with these arguments: $ARGUMENTS

Execute:
!`bun run --cwd $AI_CODING_MONOREPO pipeline $ARGUMENTS 2>&1`

Report each step's outcome. If the pipeline failed, explain which step failed and why.

Available pipelines:
- scaffold-rust   <workspace>             Rust: cargo init + generate flake.nix
- scaffold-cpp    <workspace>             C++: generate CMakeLists.txt + src/main.cpp + flake.nix
- rust-plan-cycle <workspace> [--plan <file>] [--input "..."] [--max-retries <int>] [--profile <name>]  Rust: execute a pre-written plan (plan → implement → fmt → clippy → test → coverage)
