# Architecture

This document explains the *why* behind agora's structure — the parts that
aren't obvious just from reading `flake.nix` or the module edits in
`home-manager`.

## Two consumers, one source

Agora's `.apm/` primitives feed exactly two consumption paths, and they are
kept deliberately independent:

- **home-manager** reads agora's raw git tree via `readDir` (no build, no
  apm involved) and deploys to Jan's own machines.
- **apm** reads the same tree's `apm.yml` + `.apm/` layout and deploys to
  colleague machines via `apm install`.

Neither path is privileged over the other; both read the identical
committed source. This is what "one canonical source, never drift" means in
practice — not a promise enforced by process, but a structural consequence
of there being only one tree to read.

```mermaid
flowchart LR
  subgraph agora["agora — canonical source (producer)"]
    P[".apm/ agents · skills · instructions<br/>clients/claude/.apm/ rendered + native"]
  end
  P -->|"raw source · readDir"| HM["home-manager<br/>(pure config)"]
  HM -->|"home-manager switch"| JAN["Jan's machines<br/>~/.config/opencode · ~/.claude"]
  P -->|"apm install --target"| APM["apm CLI"]
  APM --> COLL["colleagues' machines"]
```

## Why OpenCode is verbatim and Claude is rendered (Path B)

[apm](https://github.com/microsoft/apm) is a deterministic, multi-target
compiler: author primitives once, `apm install --target <client>` deploys
them with no LLM involved. For most primitives and most targets that is
exactly right — but it breaks down for one specific case in this repo.

Agora's agents are authored **as OpenCode agents**: `model:` carries an
OpenCode/Copilot model identifier (e.g. `github-copilot/claude-opus-4.8`),
and permissions are expressed as OpenCode-native `permission:` blocks
(`edit:`, `write:`, `bash:` allowlists). apm's contract for the `agents`
primitive is to pass `model` through **verbatim** to every target, Claude
Code included. That is correct and sufficient for OpenCode, since OpenCode
*is* the source format. It is not sufficient for Claude Code: a
`github-copilot/...` model string means nothing to Claude Code, and apm has
no mapping from OpenCode's `permission:` shape to Claude's
`disallowed-tools` / `allowed-tools` frontmatter.

Rather than ship a broken verbatim deploy to Claude, agora keeps its
existing LLM-based renderer (`renderers/opencode-to-claude.md` +
`renderers/render.sh`) for exactly this transform:

- Model identifiers are mapped to Claude's short names (`opus`, `sonnet`).
- OpenCode `permission:` blocks are mapped to Claude's
  `disallowed-tools` / `permissionMode` frontmatter.
- Each persona agent is re-authored as a Claude **skill** (with
  `disable-model-invocation: true`, since it should only be invoked by name,
  never auto-triggered) — Claude has no bare "agent" primitive in the shape
  agora's personas need for this.

The render is not run inside `apm install` or `nix build`: it needs model
access and is non-deterministic, so **the output is committed** — the same
"Option A" decision this repo made before apm entered the picture. What
changed is only the *packaging* layer downstream of the render; the render
itself, and the reason for it, are unchanged.

```mermaid
flowchart TB
  SRC[".apm/agents/*.agent.md<br/>.apm/skills/*/SKILL.md"]
  SRC -->|"copied verbatim"| OPKG["aios-agents-opencode<br/>target: opencode"]
  SRC -->|"render.sh (LLM, run locally)"| GEN["clients/claude/.apm/skills/<br/>(committed)"]
  NAT["native skills + CLAUDE.md instruction"] --> CPKG
  GEN --> CPKG["aios-agents-claude<br/>target: claude"]
  SRC -. "sha256" .-> MAN["manifest.json"]
  GEN -. "sha256" .-> MAN
  MAN --> CHK["checks.claude-render-fresh<br/>(nix flake check)"]
```

**The drift guard.** `checks.claude-render-fresh` is a pure (no LLM, no
network) `nix flake check`: it recomputes the sha256 of every source file
(the 15 shared skills, the 6 persona agents, and the renderer prompt
itself) and compares against `clients/claude/.apm/manifest.json`. If any
source changed since the last `render.sh` run, the check fails with
`STALE: ...`. This is the safety net that makes committing generated
content safe: it is structurally impossible to ship a Claude package that
silently drifted from its OpenCode source, because CI (and any local
`nix flake check`) catches it first.

## Primitive → target deployment map

What each `.apm/` primitive becomes, per client, once `apm install` runs:

```mermaid
flowchart LR
  AG["agents"] --> OA[".opencode/agents/&lt;n&gt;.md"]
  SK["skills"] --> AS[".config/opencode/skills/ with --legacy-skill-paths<br/>(else .agents/skills/, converged default)"]
  SK --> CS[".claude/skills/&lt;n&gt;/"]
  IN["instructions"] -->|"install stages, apm compile writes"| OM["AGENTS.md"]
  IN2["instructions (claude pkg)"] -->|"install deploys directly"| CR[".claude/rules/claude.md"]
```

Two things worth noting from this map:

- **Agents only reach OpenCode in this repo**, despite apm supporting a
  verbatim `.claude/agents/` deploy — agora's `clients/claude/apm.yml` pins
  `targets: [claude]` and never installs the *agents* primitive there at
  all; Claude gets the persona content exclusively through the rendered
  **skills** path described above.
- **Instructions are asymmetric between the two targets — verified
  empirically, not assumed.** OpenCode has no native per-file instruction
  reader: `apm install` only stages the content, and a separate
  `apm compile -t opencode` writes the actual `AGENTS.md` (install prints
  a one-line hint to this effect). Claude Code is different: `apm install`
  deploys the instruction **directly** to `.claude/rules/claude.md`, and
  running `apm compile -t claude` afterward is a documented no-op for it
  ("Claude Code reads `.claude/rules/` directly, no further action
  needed" — apm's own compile output). Neither install nor compile ever
  produces a root-level `CLAUDE.md` file in this repo's setup; Claude Code
  doesn't need one. This asymmetry is a property of apm's per-target
  contract, not a choice agora makes — see apm's targets-matrix
  documentation for the general rule (opencode/codex/gemini need a
  post-install compile for instructions; claude/cursor/windsurf/kiro do
  not).

## apm conventions used in this repo

- **Naming:** package names use the `aios-` prefix
  (`aios-agents-opencode`, `aios-agents-claude`) even though the repo itself
  is themed (`agora`) — colleagues resolve by git ref
  (`vansweej/agora[/path]`), so the package `name:` field is free to carry
  the product-facing brand.
- **`targets:` is always pinned**, never left to auto-detect — this is a
  correctness guardrail as much as a convenience: an unqualified
  `apm install` against agora's root can only ever resolve to `opencode`.
- **`includes: auto`** is set explicitly on both `apm.yml` files (rather
  than left undeclared) so `apm audit` never raises an `includes-consent`
  advisory for content that is, in fact, meant to be published.
- **`$schema` is omitted** on both manifests, so they track apm's current
  working-draft contract (matching the installed CLI) rather than pinning
  to the more conservative, slower-moving OpenAPM v0.1 shape.

These same conventions are intended to extend to the other AI-OS component
repos (cerebrum, athenaeum, ai-coding) as they gain their own apm packages —
tracked separately from agora's own migration.

## Verification performed

The claims above were verified against a real `apm` CLI (v0.26.0), not
inferred from documentation alone:

- `apm compile --validate` inside this repo: 10 chatmodes + 2 instructions
  validated with zero errors — confirms agora's OpenCode-native
  `permission:` blocks and lack of `tools:`/`color:` fields never trigger
  apm's opencode-shape warnings.
- `apm install --target opencode` against a **clean git-archive export**
  (not the live working tree): zero warnings, zero security findings, 10
  agents + 16 skills deployed. Skills landed at `.agents/skills/` by
  default; `--legacy-skill-paths` correctly restored `.opencode/skills/`.
- `apm install --target claude` against the `clients/claude` subpath, same
  clean export: zero warnings, 23 skills + 1 rule deployed, `settings.json`
  never touched, `.claude/rules/claude.md` exactly matches the source
  instruction body with frontmatter stripped by apm itself.
- `apm compile -t claude` confirmed as a no-op for the instruction ("Claude
  Code reads `.claude/rules/` directly, no further action needed"), and
  `apm compile -t opencode` confirmed as required (generates `AGENTS.md`
  from the staged instruction).
- **Gotcha found and worth remembering:** running these commands directly
  against agora's own live checkout (rather than a clean export) can trip
  apm's hidden-character security scan on gitignored build artifacts
  (`node_modules/` from unrelated tooling) that a real `apm install
  vansweej/agora` — which clones from git — would never see. Always
  validate against `git archive <ref> | tar -x` into a scratch directory,
  not the working tree.
