# agora

Canonical source for the personal "AI OS" — agents, skills, commands, tools,
and multi-client renderers, gathered in one repo.

`agora` is the **producer**. It does not manage any machine directly:
Jan's own machines are configured by `home-manager`, which consumes this
repo's raw source tree (`inputs.agora`) via `readDir` — no build, no
package, no apm in the middle. The flake outputs below exist purely to
generate distributable artifacts for colleagues who don't run Nix.

## Layout

```
agents/                     canonical OpenCode agents (source of truth)
skills/                      canonical OpenCode skills (source of truth, shared across clients)
commands/ tools/ bin/       ai-coding-coupled content (shell out to $AI_CODING_MONOREPO)
clients/
  opencode/native/          opencode-only skills, bypass the renderer (e.g. context-audit)
  claude/native/            hand-authored claude-only skills (e.g. grill-me, grill-with-docs)
  claude/generated/         COMMITTED renderer output (Option A) — see below
renderers/                   LLM transform prompts + driver (OpenCode -> Claude/Copilot)
```

## Flake outputs

### `packages.opencode-tree`

Internal whole-tree validation target. Copies the entire authored OpenCode
content tree (agents, skills, commands, bin, `AGENTS.md`, `package.json`)
verbatim into the Nix store. Not consumed by anything — it exists to catch
build breakage in the full tree. This is also `packages.default`.

### `packages.aios-agents-opencode`

The flagship, colleague-facing apm artifact. A zero-dependency subset of
the tree, built for non-Nix colleagues installing via `apm` (format still
TBD — this output is only the store-tree producer):

- **Included:** the 6 `mode: primary` agents (brainstorm, spar, teach, plan,
  explore, build), all 15 shared skills, the 1 opencode-native skill
  (context-audit), and `AGENTS.md`.
- **Excluded:** `commands/`, `tools/`, `bin/`, `package.json` — these belong
  to the ai-coding rung, which isn't offered as its own apm yet and is still
  being fine-tuned. Also excluded: the `mode: subagent` dev workhorses
  (planner, tester, debugger, reviewer) — not part of the flagship roster.

Build and inspect:

```
nix build .#aios-agents-opencode
ls result/agents result/skills
```

`checks.aios-agents-opencode` locks this contract — `nix flake check` fails
if the agent/skill counts or exclusions regress.

### `packages.aios-agents-claude`

The Claude flagship apm artifact. The OpenCode -> Claude transform
(`renderers/opencode-to-claude.md` + `renderers/render.sh`) is an LLM-based
render, which is non-deterministic and needs network + Copilot credentials —
so it cannot run inside a Nix build. **Option A (chosen): the render output
is COMMITTED** as generated source under `clients/claude/generated/skills/`,
each file carrying a `DO NOT EDIT — generated from <src>` marker. This
derivation is a pure copy of that committed tree — no LLM, no network,
identical to what home-manager's `claude.nix` module deploys on Jan's own
work Macs.

- **Included:** the 21 rendered skills (15 shared skills + 6 persona agents,
  from `clients/claude/generated/skills/`), the 2 hand-authored native
  skills (`grill-me`, `grill-with-docs` — copied whole, since
  `grill-with-docs` ships `ADR-FORMAT.md`/`CONTEXT-FORMAT.md` alongside
  `SKILL.md`), and `CLAUDE.md`.

Build and inspect:

```
nix build .#aios-agents-claude
ls result/skills   # 23 dirs
cat result/CLAUDE.md
```

`checks.aios-agents-claude` locks this contract (23 skills, marker on every
generated skill, native aux docs present, no leaked source-only
frontmatter).

### Producing / updating `clients/claude/generated/`

The render is a **manual, on-demand, local step** — not run in CI. Whenever
a shared skill, a persona agent, or the renderer prompt itself
(`renderers/opencode-to-claude.md`) changes:

```
nix develop . --command bash renderers/render.sh
git add clients/claude/generated/
git commit
```

This wipes and regenerates `clients/claude/generated/skills/` and writes
`clients/claude/generated/manifest.json` (a `{source: sha256}` map covering
all 21 sources plus the renderer prompt — 22 entries).

`checks.claude-render-fresh` is a **pure** (no LLM, no network) `nix flake
check` that recomputes each source's hash and fails with `STALE: ...` if the
committed render has drifted out of sync with its sources — the safety net
that makes Option A safe: it catches "edited a source, forgot to re-render"
before it ships to either Jan's machine or a colleague's apm.

### Forthcoming

- `aios-agents-copilot` — Copilot renderer backend is still a TODO stub
  (format undecided: chatmodes vs. skills).
- The apm archive/manifest format itself — not yet defined.
