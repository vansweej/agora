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
- plan-cycle      <workspace> [--plan <file> | --plan-ref <id>] [--input "..."] [--max-retries <int>] [--profile <name>]  Multi-language: execute a pre-written plan (from a file, or resolved from cerebrum by id) → implement → verify → commit per phase
- rust-plan-cycle <workspace> [--plan <file> | --plan-ref <id>] [--input "..."] [--max-retries <int>] [--profile <name>]  Alias of plan-cycle that forces the Rust toolchain
