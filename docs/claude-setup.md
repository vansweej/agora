# Claude Code — cerebrum setup guide

This document explains the cerebrum MCP integration for Claude Code users of agora.

## What this covers

The `plan` persona and all other agora agents can read and write to cerebrum —
a two-tier semantic memory (Synapse short-term + Cortex long-term) served as an
MCP server. This lets agents recall prior decisions, persist new ones, and hand
off knowledge across sessions.

## How it works per persona

| Persona / subagent | Recall mode | Write mode |
|--------------------|-------------|------------|
| `plan`, `spar`, `build` | AUTO at start | see below |
| `brainstorm`, `explore`, `teach` | ON-DEMAND | in-session |
| `debugger`, `reviewer`, `tester`, `planner` | ON-DEMAND | in-session |

**`plan` is special (B0 deferred clause).** Claude's built-in plan mode puts
the agent in a semi-read-only state where MCP *writes* prompt for approval.
This is expected — not a bug. Two outcomes are both safe:

- **You approve the prompt** → cerebrum write goes through, decisions are
  persisted directly.
- **You deny the prompt** → the `plan` persona emits a *memory-ready block*
  (content + suggested salience + scope + repo tag + supersede note) in the
  conversation and asks you to hand off to a writing agent to store it verbatim.
  Nothing is lost.

All other personas (including the `planner` *subagent*, which carries no
read-only overlay) write in-session normally.

## MCP server availability per persona

Three MCP servers are registered globally in Claude Code (via
`claude mcp add-json -s user`, from home-manager's `modules/claude-mcp.nix`):
`cerebrum`, `athenaeum`, and `choragos`. All three are **global** — every
persona and every session sees them. This is intentional for `cerebrum` and
`athenaeum`, and a deliberate accepted limitation for `choragos`:

| Server | Intended reach | Notes |
|--------|----------------|-------|
| `cerebrum` | all personas | continuity backbone; every persona recalls/persists memory |
| `athenaeum` | all personas | personal-library search; harmless and useful anywhere |
| `choragos` | `build` only *(by convention)* | can run a multi-minute plan-cycle that **writes code**; see below |

### Why choragos scoping is convention, not enforcement

We evaluated fencing `choragos` to `build` and deliberately did **not** ship a
render-time restriction, because Claude Code has no durable per-persona tool
fence for personas delivered as **skills** (which is how agora renders all six
personas — see `docs/architecture.md`):

- A skill's `disallowed-tools` / `allowed-tools` frontmatter is a **one-turn**
  grant: the Claude Code docs state the restriction "clears when you send your
  next message." Since a persona is invoked once at session start, any such
  fence would evaporate for the rest of the session. (Skill *instructions*
  persist across the session; skill *tool permissions* do not.)
- The only **durable** tool boundaries in Claude Code are global
  `permissions.deny` rules in `settings.json` (which would fence `choragos`
  from `build` too — unacceptable) or native subagent `tools:` frontmatter
  (which would require re-modelling the personas as subagents, an architecture
  change agora rejects).

In practice `choragos` is already build-only by prompt convention: only the
`build` persona's instructions reference the plan-cycle. The other five
personas never mention it and will not invoke it in normal use. This is a
behavioral convention, not an enforced sandbox.

## Allow-list: skip the prompts (optional)

`clients/claude/settings.json` in this repo carries four `permissions.allow`
entries that pre-approve the four read/write cerebrum tools:

```json
"mcp__cerebrum__cerebrum_recall",
"mcp__cerebrum__cerebrum_recall_by_scope",
"mcp__cerebrum__cerebrum_remember",
"mcp__cerebrum__cerebrum_memorize"
```

`cerebrum_forget` is intentionally excluded — destructive operations still
prompt individually.

### Jan (home-manager)

Jan's home-manager configuration deploys `clients/claude/settings.json`
directly to `~/.claude/settings.json`. No manual step needed.

### apm colleagues

apm's `apm install --target claude` never deploys `settings.json` (verified:
it does not appear in apm's write plan). To get prompt-free cerebrum writes,
copy the four entries above into your own `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__cerebrum__cerebrum_recall",
      "mcp__cerebrum__cerebrum_recall_by_scope",
      "mcp__cerebrum__cerebrum_remember",
      "mcp__cerebrum__cerebrum_memorize"
    ]
  }
}
```

Without this, Claude will prompt per cerebrum call. For most operations that
is fine. For the `plan` persona specifically, the deferred clause in its
prompt covers the denial path — so this is ergonomic, not functional.

## Prerequisite: cerebrum MCP server

The cerebrum MCP server must be running and registered in your Claude Code MCP
configuration for any of the above to apply. If cerebrum is absent, all agents
degrade gracefully: recall steps are skipped, write steps are skipped, and the
`plan` persona's deferred clause produces a memory-ready block you can store
later.
