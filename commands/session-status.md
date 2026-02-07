---
description: Check status of all active VibeKanban workspace sessions
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task
---

# Workspace Session Status (Experimental)

> **This command is experimental and actively evolving.** VK workspace session behavior is being tested. Expect changes.

## Context

You are checking the status of tasks that have been delegated to VibeKanban workspace sessions (via `/delegate-task` or `/delegate-batch`) or are being worked on in parallel (via `/work-parallel`). This gives the user a snapshot of all active work across sessions.

## Instructions

### 1. Fetch Project and Task Status

- Use `list_projects` to find the project
- Use `list_tasks` to get all tasks and their current status
- If `docs/development-plan.md` exists, read it to get additional context (task IDs, epic names, acceptance criteria)

### 2. Categorize Active Tasks

Group tasks by their current status:

- **In Progress** (`inprogress`) -- tasks currently being worked on by an agent or user
- **In Review** (`inreview`) -- tasks where the agent has finished and work is ready for human review
- **Recently Completed** (`done`) -- tasks completed in the current session or recent timeframe

### 3. Check for Local Worktrees

Run `git worktree list` to detect any active worktrees. Match worktree branch names to tasks:

- Branch `task/2.3-add-user-api` maps to plan task 2.3
- Branch `task/fix-login-bug` maps to a VK-only task by title

Report which tasks have active worktrees and their paths.

### 4. Present the Status Report

```
## Active Sessions

### In Progress (3 tasks)

| Task | Status | Type | Location |
|------|--------|------|----------|
| 2.3 - Add user API | inprogress | Worktree | ../myproject-worktrees/task-2.3-add-user-api/ |
| 3.1 - Setup database | inprogress | VK Workspace | Remote (CLAUDE_CODE) |
| 4.2 - Add logging | inprogress | Worktree | ../myproject-worktrees/task-4.2-add-logging/ |

### In Review (1 task)

| Task | Status | Type | Action Needed |
|------|--------|------|---------------|
| 1.4 - Setup CI/CD | inreview | VK Workspace | Review diff in VK, test branch, merge or request revisions |

### Recently Completed (2 tasks)

| Task | Status |
|------|--------|
| 1.1 - Project setup | done |
| 1.2 - Configure linting | done |

### Blocked Tasks (waiting on in-progress work)

| Task | Blocked By |
|------|-----------|
| 2.4 - Add auth middleware | 2.3 (inprogress) |
| 3.2 - Seed database | 3.1 (inprogress) |

---

### Summary
- **3** tasks in progress
- **1** task ready for review
- **2** tasks will unblock when current work completes
```

### 5. Suggest Actions

Based on the status, suggest relevant next steps:

- **Tasks in review**: "Task 1.4 is ready for review. Open it in VK to see the diff, or cd into the worktree to test."
- **Blocked tasks about to unblock**: "When task 2.3 completes, task 2.4 will be ready to start."
- **No active work**: "No tasks are in progress. Run `/work-next` to start the next task, or `/work-parallel` for parallel execution."
- **Many tasks in review**: "You have [N] tasks waiting for review. Consider reviewing and merging them before starting more work."
- **Stale in-progress tasks**: If tasks have been `inprogress` without a corresponding worktree or active session, flag them: "Task [X] is marked in progress but has no active worktree or session. It may be stale."

### 6. Provide Cleanup Guidance

If there are worktrees for completed or merged tasks:

```
### Cleanup Available

These worktrees can be removed (tasks are done/merged):
- git worktree remove ../myproject-worktrees/task-1.4-setup-cicd

Or clean up all finished worktrees:
- git worktree prune
```

### 7. Handle Edge Cases

- **No VK project**: Tell the user to run `/generate-tasks` first.
- **No tasks in progress**: Report that nothing is active. Suggest `/work-next` or `/work-parallel`.
- **No development plan**: Work from VK tasks only. Note that epic context and acceptance criteria are unavailable.
- **Git worktree command unavailable**: Skip worktree detection. Report VK status only.
- **Worktrees exist without matching VK tasks**: Flag as orphaned worktrees that may need cleanup.
