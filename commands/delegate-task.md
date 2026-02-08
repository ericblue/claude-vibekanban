---
description: Delegate a task to a separate VibeKanban workspace session with a chosen agent
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task, mcp__vibe_kanban__start_workspace_session, mcp__vibe_kanban__list_repos, mcp__vibe_kanban__get_repo
version: 0.3.1-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Delegate Task to Workspace Session (Experimental)

> **This command is experimental and actively evolving.** VK workspace session behavior is being tested. Expect changes.

## Context

You are delegating a task to a separate VibeKanban workspace session. This spawns an entirely separate agent instance (Claude Code, Cursor, Codex, Gemini, Copilot, or other supported executors) paired with a specific task and repository. The remote agent works independently in its own environment and branch.

This is different from `/work-parallel` (Tier 1), which uses local git worktrees. This command uses VibeKanban's `start_workspace_session` API (Tier 2) for full remote delegation.

## Instructions

### 1. Identify the Task

The user can identify a task in any of these ways:

- **Plan task ID** (e.g., `1.2`, `2.1`) -- Look it up in the development plan task tables
- **Task title or partial title** (e.g., `"auth"`, `"set up database"`) -- Fuzzy match against both the development plan and VibeKanban tasks
- **No input provided** -- List available tasks and ask which one to delegate

**Resolution logic:**

1. If the input matches a plan task ID pattern (digits.digits), look it up in `docs/development-plan.md`
2. Otherwise, treat it as a title search:
   - Use `list_projects` and `list_tasks` to fetch all VK tasks
   - Also check task titles in `docs/development-plan.md` if it exists
   - Find tasks whose title contains the search text (case-insensitive)
   - If multiple matches, show them and ask the user to pick one
   - If exactly one match, confirm it with the user before proceeding
3. If no match is found, show available tasks and ask the user to clarify

The task **must** exist in VibeKanban (have a VK task ID). If it only exists in the plan, tell the user to run `/generate-tasks` first.

### 2. Gather Context

Read these sources to understand the task:

1. **Development Plan** (`docs/development-plan.md`) -- if the task exists in the plan:
   - Task row: ID, title, description, priority, complexity, dependencies
   - Task Details: acceptance criteria
   - Epic context

2. **VibeKanban task** -- use `get_task` to fetch the full task details

3. **PRD** (`docs/prd.md`) -- relevant sections for context

### 3. Check Dependencies

- Parse the "Depends On" column for this task
- Use `list_tasks` / `get_task` to verify each dependency is `done` in VK
- If dependencies are NOT satisfied:
  - List which dependencies are incomplete
  - Warn the user that delegating this task may cause issues
  - Ask if they want to proceed anyway or pick a different task

### 4. Choose the Executor

Ask the user which agent should handle the task (if not already specified):

```
## Choose an Agent

Which agent should work on this task?

1. **CLAUDE_CODE** - Claude Code (default)
2. **CURSOR_AGENT** - Cursor
3. **CODEX** - OpenAI Codex
4. **GEMINI** - Google Gemini
5. **COPILOT** - GitHub Copilot
6. **DROID** - Custom agent

Or specify a different executor name.
```

If the user doesn't specify, default to `CLAUDE_CODE`.

### 5. Determine Repository and Branch

- Use `list_repos` to find the repositories associated with the project
- Use `get_repo` to get repository details
- Determine the base branch (typically `main` or `master`)

### 6. Confirm Before Delegating

Present a summary and ask for confirmation:

```
## Delegation Summary

### Task
- **ID:** [Task ID] - [Title]
- **Priority:** [High/Medium/Low]
- **Complexity:** [S/M/L/XL]
- **Dependencies:** [All satisfied / List unmet]

### Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

### Workspace Session
- **Executor:** [CLAUDE_CODE / CURSOR_AGENT / etc.]
- **Repository:** [repo name]
- **Base branch:** [main]

Proceed with delegation?
```

**Do not start the workspace session until the user explicitly confirms.**

### 7. Start the Workspace Session

After user confirmation:

1. Use `start_workspace_session` with:
   - `task_id`: the VK task UUID
   - `executor`: the chosen agent type (e.g., `CLAUDE_CODE`)
   - `repos`: array with `repo_id` and `base_branch`

2. Report the result:

```
## Workspace Session Started

- **Task:** [ID] - [Title]
- **Agent:** [executor type]
- **Status:** Session launched

The agent is now working on this task in its own environment and branch.
```

### 8. Provide Post-Delegation Guidance

```
## Next Steps

1. **Monitor**: Check task status in the VibeKanban board
2. **Review**: When the task moves to `inreview`:
   - Open the task in VK to see the diff and full session history
   - Leave inline comments on specific lines of code
   - Send revision requests if changes are needed -- VK will start a new agent session in the same feature branch
3. **Merge**: When satisfied, use VK's merge button to merge the branch to main
4. **Sync**: Run `/sync-plan` to update the development plan

Use `/session-status` to check on active workspace sessions.
```

### 9. Handle Edge Cases

- **Task not in VK**: The task must exist in VibeKanban to delegate. Tell the user to run `/generate-tasks` first.
- **Task already in progress**: Warn the user. Ask if they want to delegate anyway (may create a conflicting session).
- **Task already done**: Inform the user. Ask if they want to re-delegate for rework.
- **No repos found**: Use `list_repos` to check. If no repos are configured for the project, inform the user that the VK project needs a repository linked.
- **Workspace session fails to start**: Report the error. Suggest checking VK project configuration and repo settings.
- **Multiple repos**: If the project has multiple repos, ask the user which one(s) the task should work in.
