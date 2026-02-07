---
description: Delegate multiple independent tasks to parallel VibeKanban workspace sessions
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task, mcp__vibe_kanban__start_workspace_session, mcp__vibe_kanban__list_repos, mcp__vibe_kanban__get_repo
---

# Delegate Batch to Workspace Sessions (Experimental)

> **This command is experimental and actively evolving.** VK workspace session behavior is being tested. Expect changes.

## Context

You are delegating multiple tasks to separate VibeKanban workspace sessions for parallel execution. This is the batch version of `/delegate-task` -- it analyzes the backlog for independent tasks, lets the user review and adjust the set, then starts a workspace session for each.

Each workspace session spawns a separate agent instance (Claude Code, Cursor, Codex, Gemini, Copilot, or other supported executors) working in its own environment and branch.

This is a Tier 2 command using VibeKanban's `start_workspace_session` API. For local parallel execution using git worktrees, see `/work-parallel` (Tier 1).

## Instructions

### 1. Read the Development Plan

Read `docs/development-plan.md`. If it doesn't exist, inform the user and suggest running `/create-plan` first.

Extract:
- All tasks with their ID, title, priority, complexity, dependencies, and VK task ID
- Epic structure and order
- Task Details (acceptance criteria) for each task

### 2. Fetch Current Status from VibeKanban

- Use `list_projects` to find the project
- Use `list_tasks` to get all tasks and their current status
- Match VK tasks to plan tasks using `<!-- vk:TASK_ID -->` references

### 3. Identify the Task Set

`/delegate-batch` supports two invocation modes:

**Explicit mode** -- user provides task IDs:

```
/delegate-batch 1.3 2.1 3.2
```

Parse the provided IDs and look them up in the plan and VK. Skip to step 4 (validation).

**Recommended mode** -- no task IDs provided:

```
/delegate-batch
```

Analyze the backlog to identify tasks that can safely run in parallel:

1. Find all **available** tasks: status is `todo` in VK, all dependencies are `done`, has a VK task ID
2. Identify tasks with **no mutual dependencies** -- two tasks are safe to parallelize only if neither depends on the other, directly or transitively
3. Rank candidate groups by: priority, complexity, epic order, unblocking potential
4. Propose the top candidates, up to the default cap of **3 tasks**

### 4. Validate Independence

For each task in the candidate set, verify:

- **Has VK task ID**: required for `start_workspace_session`. If missing, exclude and suggest running `/generate-tasks`
- **Dependencies satisfied**: all `Depends On` tasks are `done` in VK
- **No mutual dependencies**: no candidate task depends on another candidate task
- **VK-only task warning**: if a task lacks dependency data, warn the user

If any validation fails, explain the issue and suggest removing the problematic task.

### 5. Choose the Executor

Ask the user which agent should handle the tasks (if not already specified):

```
Which agent should work on these tasks?

1. CLAUDE_CODE (default)
2. CURSOR_AGENT
3. CODEX
4. GEMINI
5. COPILOT
6. DROID
```

The same executor is used for all tasks in the batch. If the user wants different executors per task, suggest using `/delegate-task` individually.

### 6. Present for Review

Show the proposed batch to the user:

```
## Batch Delegation Plan

### Tasks to delegate (3 of 5 available)

| # | Task ID | Title | Priority | Complexity | AC Count |
|---|---------|-------|----------|------------|----------|
| 1 | 2.3 | Add user API | High | M | 4 |
| 2 | 3.1 | Setup database | High | S | 3 |
| 3 | 4.2 | Add logging | Medium | S | 2 |

### Also available (not included)
- 3.3 - Add notifications (Medium, M)
- 5.1 - Write unit tests (Low, S)

### Workspace Configuration
- **Executor:** CLAUDE_CODE
- **Repository:** [repo name]
- **Base branch:** main

### Warnings
- None

Adjust this set? You can:
- Remove tasks by number (e.g., "remove 3")
- Add tasks from the available list (e.g., "add 3.3")
- Change the count (e.g., "just delegate 2")

Or confirm to proceed.
```

**Do not start any workspace sessions until the user explicitly confirms.**

### 7. Determine Repository and Branch

- Use `list_repos` to find the repositories associated with the project
- Use `get_repo` to get repository details
- Determine the base branch (typically `main` or `master`)

### 8. Start Workspace Sessions

After user confirmation, start a workspace session for each task:

For each task in the approved set:

1. Use `start_workspace_session` with:
   - `task_id`: the VK task UUID
   - `executor`: the chosen agent type
   - `repos`: array with `repo_id` and `base_branch`

2. Track the result (success or failure) for each

Report the results:

```
## Workspace Sessions Started

| Task | Agent | Status |
|------|-------|--------|
| 2.3 - Add user API | CLAUDE_CODE | Started |
| 3.1 - Setup database | CLAUDE_CODE | Started |
| 4.2 - Add logging | CLAUDE_CODE | Started |

3 of 3 sessions launched successfully.
```

If any session fails to start, report the error and continue with the remaining tasks.

### 9. Provide Post-Delegation Guidance

```
## Next Steps

1. **Monitor**: Check task status in the VibeKanban board or with `/session-status`
2. **Review**: When tasks move to `inreview`:
   - Open each task in VK to see the diff and session history
   - Leave inline comments for revision requests
   - Test each branch before merging
3. **Merge sequentially**:
   - Merge the first completed branch to main via VK
   - Subsequent branches may need rebasing before merge
   - Watch for conflicts in shared files (registries, configs, index files)
4. **Sync**: Run `/sync-plan` after all branches are merged
```

### 10. Handle Edge Cases

- **No available tasks**: All tasks are done, in progress, or blocked. Report what's blocking.
- **Only 1 available task**: Suggest using `/delegate-task` instead.
- **Tasks missing VK IDs**: Exclude from the batch. Tell user to run `/generate-tasks`.
- **No repos found**: Inform the user that the VK project needs a repository linked.
- **Partial batch failure**: If some sessions start and others fail, report which succeeded and which failed. Don't roll back successful sessions.
- **User wants more than 3**: Allow it, but warn about resource consumption and token costs.
- **User wants different executors per task**: Suggest using `/delegate-task` individually for each.
