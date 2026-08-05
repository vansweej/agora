# AGENTS.md

`agora` is a **content repository**, not an application: it is the canonical source
for AI-OS agents, skills, and instructions, packaged as two apm packages. There is
no app to run, no test suite, no lint step. The work is authoring markdown
primitives and keeping the Claude render in sync. Read `docs/architecture.md` for
the full rationale.

## Golden rule: the Claude render must not drift

`clients/claude/.apm/skills/` is **generated, committed source** (each file carries
a DO-NOT-EDIT header). If you edit any *render source*, you MUST re-run the renderer
and commit the result, or `nix flake check` fails with `STALE: ...`.

Render sources (the only things that trigger a re-render):
- the **15 shared skills** in `.apm/skills/*` — every dir **except** `context-audit`
- the **3 manual persona agents** (render to Claude skills): `brainstorm teach build`
- the **3 specialist subagents** (render to Claude agent files): `explore spar plan`
- the **coordinator** (renders to the Claude skill `workflow-explore`):
  `.apm/agents/coordinator.agent.md`
- the renderer prompt `renderers/opencode-to-claude.md`

Re-render (needs model access; non-deterministic; run locally, never in CI):
```bash
nix develop . --command bash renderers/render.sh
git add clients/claude/.apm/
git commit
```
Then verify the pure drift guard passes:
```bash
nix develop . --command nix flake check   # checks.claude-render-fresh
```

Do NOT hand-edit generated skills. Exceptions: `grill-me` and `grill-with-docs`
under `clients/claude/.apm/skills/` are **hand-authored native** Claude skills — the
render script leaves them untouched.

Not render sources (editing these needs no re-render): the `context-audit` skill,
the dev subagents `debugger planner reviewer tester`, and the two native Claude
skills above.

## Environment

- Everything runs inside the Nix dev shell: `nix develop . --command <cmd>`
  (provides `bun`, `jq`, `coreutils`). `render.sh` relies on `sha256sum`/`jq` from
  this shell — running it outside Nix is unsupported.
- The flake exposes only a `devShell` and `checks.claude-render-fresh`. There is no
  `packages` output by design — distribution is via apm and home-manager, not Nix
  store trees.

## Verification (there is no test/lint/typecheck)

This repo has no test suite, linter, or typecheck target. Ignore any generic
"run tests/lint" instinct. The only verification is the pure drift guard:

    nix develop . --command nix flake check   # checks.claude-render-fresh

It passes for content-only changes (e.g. package.json, docs). It fails with
`STALE: ...` only if you edited a render source without re-running
renderers/render.sh (see "Golden rule" above).

## Repo layout that isn't obvious

- Root `apm.yml` → package `aios-agents-opencode` (`targets: [opencode]`).
  `clients/claude/apm.yml` → package `aios-agents-claude` (`targets: [claude]`).
  `targets:` is always pinned on purpose; an unqualified `apm install` can never
  cross-deploy to the wrong client.
- `.apm/agents/` holds 11 OpenCode agents: 4 primary agents (`coordinator`,
  `brainstorm`, `teach`, `build`), 3 specialist subagents (`explore spar plan`,
  `mode: subagent`, invoked only via `coordinator`'s `task` tool), and 4 dev
  subagents (`debugger reviewer tester planner`). `explore`, `spar`, and `plan`
  also render to Claude as real `.claude/agents/` files (so Claude's own Task
  tool can address them the same way) — this is new: agora used to ship
  personas to Claude only as skills, never as agents.
- `.opencode/agent/renderer.md` is the tools-disabled agent `render.sh` drives — not
  a product agent.
- `commands/`, `tools/`, `bin/` are **home-manager-only** and are NOT part of either
  apm package. They shell out to `$AI_CODING_MONOREPO` (set by Home Manager); they
  do nothing here without that env var.
- Root `package.json` (`@opencode-ai/plugin`) exists **only** as dev-time
  types for the three `tools/*.ts`; it is NOT shipped in either apm package
  and is not a runtime dependency. `bun.lock` and `node_modules/` are
  gitignored. The tools themselves are home-manager-only.

## apm gotcha (verified)

Validate `apm install` against a **clean export**, never the live working tree:
```bash
git archive <ref> | tar -x -C <scratch-dir>
```
apm's local-path installer scans the literal directory on disk, so gitignored
artifacts (`node_modules/`, `result/`) can trip its hidden-character security scan
even though a real git-cloned install would never see them.
