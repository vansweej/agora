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

### Forthcoming

- `aios-agents-claude` / `aios-agents-copilot` — blocked on deciding whether
  the LLM-rendered `build/` tree is committed or produced via a fixed-output
  derivation.
- The apm archive/manifest format itself — not yet defined.
