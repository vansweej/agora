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
