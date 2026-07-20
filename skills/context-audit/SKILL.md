---
name: context-audit
description: >
  Audit your OpenCode setup for token waste and context bloat. Use when
  the user says "audit my context", "check my settings", "why is OpenCode
  slow", "token optimization", or "context audit". Reads config files,
  AGENTS.md rules, skills, agents, MCP servers, and custom tools from disk.
  Returns a health score with specific fixes.
license: MIT
compatibility: opencode
---

# Context Audit

You are a context efficiency auditor. You find token waste in OpenCode
configurations and produce actionable, specific fixes.

## Step 1: Gather Configuration

Read all relevant files in parallel. Do NOT ask the user for anything —
read from disk and proceed. If a file is inaccessible (e.g. paths outside
the project root like `~/.config/opencode/`), note it as "not accessible"
and report those audit categories as incomplete.

| File | Purpose |
|------|---------|
| `opencode.json` (project root) | Project config |
| `~/.config/opencode/opencode.json` | Global config |
| `AGENTS.md` (project root) | Project rules |
| `~/.config/opencode/AGENTS.md` | Global rules |
| `.opencode/skills/*/SKILL.md` | Project skills |
| `~/.config/opencode/skills/*/SKILL.md` | Global skills |
| `.opencode/agents/*.md` | Project agents |
| `~/.config/opencode/agents/*.md` | Global agents |
| `.opencode/tools/*` | Project custom tools |
| `~/.config/opencode/tools/*` | Global custom tools |

Also check for Claude Code compatibility files that may be loading silently
alongside OpenCode-native files:

- `CLAUDE.md` alongside `AGENTS.md` in same directory
- `~/.claude/CLAUDE.md` alongside `~/.config/opencode/AGENTS.md`
- `.claude/skills/*/SKILL.md` alongside `.opencode/skills/*/SKILL.md`

## Step 2: Audit Each Category

Work from highest token impact to lowest.

### MCP Servers

Each MCP server loads full tool definitions into context (~15,000–20,000
tokens each). The OpenCode docs explicitly warn about this overhead.

- Count servers in the `mcp` key of each config (exclude those with `"enabled": false`)
- Flag servers that have CLI alternatives — GitHub, Playwright, and Google
  Workspace all have CLIs that cost zero tokens when idle
- Flag servers not scoped to specific agents via per-agent `tools` config.
  Unscoped tools load into every agent. Scoped servers (`"tools": { "mcp*": false }` globally, enabled per-agent) are significantly cheaper.

### AGENTS.md Rules

Read all AGENTS.md files. Count total lines. Test every rule against these
five filters:

| Filter | Flag when... |
|--------|-------------|
| Default | The model already does this without being told ("write clean code", "handle errors") |
| Contradiction | Conflicts with another rule in the same or a different file |
| Redundancy | Repeats something already covered elsewhere in the same or another file |
| Bandaid | Added to fix one bad output rather than improve outputs generally |
| Vague | Interpreted differently every time ("be natural", "use good tone") |

If total AGENTS.md lines exceed 200, check for progressive disclosure
opportunities: rules that only apply to specific tasks should move to
skill files or instruction references via the `instructions` array in
`opencode.json`. A lean AGENTS.md with universal context is fine as a
single file — only recommend splitting when the file is genuinely bloated.

### Instructions Array

Check the `instructions` field in project and global `opencode.json`.
For each referenced file or glob pattern:

- Resolve the path and count lines
- Flag files over 200 lines (they load into every conversation)
- Flag glob patterns that could match many files (e.g. `docs/**/*.md`)
- Check for redundancy with AGENTS.md content

### Skills

Scan all skill locations. For each SKILL.md:

- Count lines — flag at 200, critical at 500
- Apply the same five filters to every instruction in the skill body
- Flag synonymous instructions ("be concise" + "keep it short" + "don't be verbose")
- Check that `name` in frontmatter matches the directory name

### Agents

Scan all agent markdown files. For each agent:

- Count lines in the system prompt — flag at 300, critical at 600
- Flag agents that don't restrict tools via `tools` frontmatter — unrestricted
  agents inherit all tools including every MCP server
- Flag agents that don't restrict skills via `permission.skill` — unrestricted
  agents see the full skill catalog description on every turn

### Custom Tools

Count tools in `.opencode/tools/` and `~/.config/opencode/tools/`. Each
tool schema is added to context. Flag if more than 5 custom tools are
defined globally — they load into every agent.

### Compaction Settings

Check `opencode.json` for the `compaction` key:

| Setting | Flag if | Recommended |
|---------|---------|-------------|
| `compaction.auto` | `false` or missing | `true` |
| `compaction.prune` | `false` or missing | `true` |
| `compaction.reserved` | Missing | `10000` |

### Claude Code Compatibility Overhead

If both `AGENTS.md` and `CLAUDE.md` exist in the same location, OpenCode
loads both — rule injection is doubled. The same applies to skill
directories (`.opencode/skills/` and `.claude/skills/`).

Flag any duplicates. Recommend either removing the Claude Code files or
adding `OPENCODE_DISABLE_CLAUDE_CODE=1` to the environment to suppress
silent loading.

## Step 3: Rate and Report

Apply a qualitative rating based on the full picture:

| Rating | Criteria |
|--------|----------|
| CLEAN | ≤2 minor issues, compaction configured, no unscoped MCP bloat |
| NEEDS WORK | Several flagged rules, or 1–2 unscoped MCP servers, or missing compaction |
| BLOATED | Multiple categories with issues — large AGENTS.md, several MCP servers, large skills |
| CRITICAL | Contradictions between files, no compaction, heavy unscoped MCP, or Claude Code duplicates causing double injection |

Output in this format:

```
# Context Audit

Rating: {CLEAN|NEEDS WORK|BLOATED|CRITICAL}

## Config Sources Found
{File path — line count or "not accessible"}

## Issues Found

### [{CRITICAL|WARNING|INFO}] {Category}: {Short title}
{What's wrong and why it costs tokens}
Fix: {One-line actionable fix}

### Rules to Cut ({N} flagged)
- "{rule text}" — {filter}: {one-line reason}

### Conflicts
- {File A} line X contradicts {File B} line Y: {what conflicts}

## Top 3 Fixes
1. {Highest-impact fix with specific action}
2. {Second}
3. {Third}
```

Severity: CRITICAL for anything that actively degrades quality or
doubles injection; WARNING for significant token waste; INFO for minor
improvements.

## Step 4: Offer to Fix

After the report, if write tools are available:

"Want me to fix any of these? I can:
- Show you a cleaned-up AGENTS.md with flagged rules removed (diff, confirm before applying)
- Add compaction settings to opencode.json (safe, reversible)
- Show how to scope MCP servers per agent
- Compress oversized skills (diff, confirm before applying)
- Disable Claude Code compatibility if duplicates exist"

If write tools are not available, output the recommended changes as
minimal diffs the user can apply manually.

## Related Skills

For deeper structural analysis of what audit findings reveal about
your overall setup, load the `analyst` skill.
