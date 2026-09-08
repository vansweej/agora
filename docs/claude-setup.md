# Claude Code — cerebrum setup guide

This document explains the cerebrum MCP integration for Claude Code users of agora.

For real work, the Claude entry point is `/workflow-explore`. Invoke it
explicitly to run the explore → plan ↔ spar → confirmation → stored-plan
workflow; ordinary factual questions and casual chat are answered directly.

## What this covers

The `coordinator` (rendered as the Claude skill `workflow-explore`) and the 3
manual persona agents (`brainstorm`, `teach`, `build`) can read and write to
cerebrum — a two-tier semantic memory (Synapse short-term + Cortex long-term)
served as an MCP server. This lets these agents recall prior decisions,
persist new ones, and hand off knowledge across sessions. The 3 specialist
subagents (`explore`, `spar`, `plan`, rendered as real `.claude/agents/`
files) are pure-return: they may call `cerebrum_recall` for grounding, but
never `cerebrum_remember`/`cerebrum_memorize` — persistence is exclusively
`coordinator`'s responsibility.

## How it works per agent

| Agent | Recall mode | Write mode |
|--------------------|-------------|------------|
| `coordinator`, `build` | AUTO at start | in-session (see below for `coordinator`'s plan storage) |
| `brainstorm`, `teach` | ON-DEMAND | in-session |
| `explore`, `spar`, `plan` | ON-DEMAND | never — pure-return, no cerebrum writes |
| `debugger`, `reviewer`, `tester`, `planner` | ON-DEMAND | in-session |

**`coordinator` stores the approved plan, not a deferred handoff.** Once its
render-and-confirm gate is satisfied, `coordinator` stores the plan under
scope `plan:<uuid>` via `cerebrum_remember`, promotes it with
`cerebrum_memorize`, and upserts a per-repo plan-index entry — all directly,
in-session. Claude's plan mode may still prompt for approval on each write
(see below); there is no deferred/memory-ready-block fallback path anymore
(that was the old `plan` persona's behavior, before it became a pure-return
subagent with no cerebrum writes at all) — if a write is denied, it simply
doesn't persist and `coordinator` will say so.

## MCP server availability per agent

Three MCP servers are registered globally in Claude Code (via
`claude mcp add-json -s user`, from home-manager's `modules/claude-mcp.nix`):
`cerebrum`, `athenaeum`, and `choragos`. All three are **global** — every
agent and every session sees them. This is intentional for `cerebrum` and
`athenaeum`, and a deliberate accepted limitation for `choragos`:

| Server | Intended reach | Notes |
|--------|----------------|-------|
| `cerebrum` | all agents | continuity backbone; the 4 cerebrum-writing agents recall/persist memory, the 3 specialist subagents may recall |
| `athenaeum` | all agents | personal-library search; harmless and useful anywhere |
| `choragos` | `build` only *(by convention)* | can run a multi-minute plan-cycle that **writes code**; see below |

As of the athenaeum-wiring change, three personas actively invoke
`athenaeum_search` in their instructions: `teach` (concept grounding and
external resources), `brainstorm` (prior-art research), and `coordinator`
(grounding before delegation). This is prose-level guidance only — athenaeum is
already globally registered, so no per-agent Claude configuration changes with
this. Whether any of these MCP tools run without prompting is controlled by
enterprise-managed Claude settings; see the policy section below.

### Why choragos scoping is convention, not enforcement

We evaluated fencing `choragos` to `build` and deliberately did **not** ship a
render-time restriction for it, because Claude Code has no durable
per-agent tool fence for agents delivered as **skills** — which is how
`build` (and `brainstorm`, `teach`, `coordinator`) render, per
`docs/architecture.md`:

- A skill's `disallowed-tools` / `allowed-tools` frontmatter is a **one-turn**
  grant: the Claude Code docs state the restriction "clears when you send your
  next message." Since a skill is invoked once at session start, any such
  fence would evaporate for the rest of the session. (Skill *instructions*
  persist across the session; skill *tool permissions* do not.)
- The only **durable** tool boundaries in Claude Code are global
  `permissions.deny` rules in `settings.json` (which would fence `choragos`
  from `build` too — unacceptable) or native subagent `tools:` frontmatter.
  Agora *does* now render 3 agents (`explore`, `spar`, `plan`) as real
  Claude subagents with a durable `tools:` allowlist — but none of them
  touch `choragos` in the first place (they are read-only specialists), so
  this durable mechanism doesn't help scope `choragos` to `build`, which
  remains a skill.

In practice `choragos` is already build-only by prompt convention: only the
`build` persona's instructions reference the plan-cycle. The other agents
never mention it and will not invoke it in normal use. This is a
behavioral convention, not an enforced sandbox.

## Enterprise-managed MCP permission policy

`/status` on Jan's machine reports **Enterprise managed settings (plist)**.
Managed settings take precedence over user settings, and the enterprise policy
currently requires approval even though the user settings contain an allow rule.
Agora and Home Manager deliberately do not deploy `settings.json` or an
unsupported `~/.claude/settings.local.json`; neither can override that policy.

For prompt-free access, the enterprise Claude Code administrator must add
allow rules to the managed policy. The current Home Manager registrations use
these server names:

```json
{
  "permissions": {
    "allow": [
      "mcp__cerebrum-mcp__*",
      "mcp__athenaeum-mcp__*",
      "mcp__choragos-mcp__*"
    ]
  }
}
```

`cerebrum-mcp` includes destructive `cerebrum_forget`, which the coordinator
uses for plan-index replacement and session sweeping. `choragos-mcp` can run a
code-writing plan cycle, so its inclusion is a deliberate administrator
decision rather than a requirement for the workflow-explore completion path.

### Adding another MCP server

When Home Manager registers a new Claude MCP server, use its exact registration
name to derive the permission prefix: `mcp__<server-name>__*`. Add that rule to
the enterprise-managed allow policy only after the server owner documents the
tools, their read/write effects, and the intended Claude agents. If the
enterprise policy keeps the server prompting, no Home Manager or agora change
is necessary; users approve calls individually.

Task and Skill permission rules, if Claude prompts for them, must be copied
verbatim from the live prompt rather than inferred from MCP naming.

### apm colleagues

`apm install --target claude` does not install any settings file. Colleagues
must follow their organization’s managed-policy process, or approve prompted
MCP calls individually.

## Prerequisite: cerebrum MCP server

The cerebrum MCP server must be running and registered in your Claude Code MCP
configuration for any of the above to apply. If cerebrum is absent, all agents
degrade gracefully: recall steps are skipped, and write steps are skipped —
`coordinator` will tell you the plan couldn't be persisted rather than
silently proceeding.
