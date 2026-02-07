---
description: Check status of all active work across local worktrees and VK sessions
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task
version: 0.3-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Session & Worktree Status (Experimental)

> **This command is experimental and actively evolving.** Expect changes.

## Context

You are checking the status of all active work -- both local parallel sessions (Tier 1 worktrees from `/work-parallel`) and remote delegated sessions (Tier 2 VK workspace sessions from `/delegate-task` or `/delegate-batch`). This gives the user a unified snapshot across all execution mechanisms.

**How it works across tiers:**

- **Both tiers**: VK task status (`inprogress`, `inreview`, `done`) is always available because all sessions update VK via `update_task`. This is the universal signal.
- **Tier 1 additions**: Local worktree detection via `git worktree list`, git commit activity in worktree branches, and log file checks for headless sessions.
- **Tier 2 additions**: VK workspace session status and history are available in the VK UI.

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

### 5. Check for Observable Progress

For tasks with active worktrees, check for recent git activity as a proxy for session progress:

```bash
git -C ../myproject-worktrees/task-2.3-add-user-api log --oneline -5 2>/dev/null
```

If there are recent commits, the session is making progress. If the branch has no commits beyond the base, the session may still be starting up or may be stuck.

Also check for log files if sessions were launched in headless mode:

```bash
ls ../myproject-worktrees/*.log 2>/dev/null
```

If log files exist, report their last modification time and tail the last few lines to show recent activity.

Report this as a "Session Activity" section:

```
### Session Activity

| Task | Branch | Last Commit | Log File |
|------|--------|------------|----------|
| 2.3 - Add user API | task/2.3-add-user-api | 3 min ago: "Add user endpoint" | task-2.3.log (active) |
| 3.1 - Setup database | task/3.1-setup-database | 8 min ago: "Add schema migration" | task-3.1.log (active) |
| 4.2 - Add logging | task/4.2-add-logging | (no commits yet) | No log file |
```

If a task has no commits and no log activity, suggest the user check on it:

```
⚠ Task 4.2 has no commits and no log activity. The session may still be starting, or it may be stuck.
  - If using headless mode: check if the process is still running
  - If using Agent Teams: ask the lead about teammate status
  - If using manual terminals: switch to that terminal to check
```

### 6. Suggest Actions

Based on the status, suggest relevant next steps:

- **Tasks in review**: "Task 1.4 is ready for review. Open it in VK to see the diff, or cd into the worktree to test."
- **Blocked tasks about to unblock**: "When task 2.3 completes, task 2.4 will be ready to start."
- **No active work**: "No tasks are in progress. Run `/work-next` to start the next task, or `/work-parallel` for parallel execution."
- **Many tasks in review**: "You have [N] tasks waiting for review. Consider reviewing and merging them before starting more work."
- **Stale in-progress tasks**: If tasks have been `inprogress` without a corresponding worktree or active session, flag them: "Task [X] is marked in progress but has no active worktree or session. It may be stale."

### 7. Provide Cleanup Guidance

If there are worktrees for completed or merged tasks:

```
### Cleanup Available

These worktrees can be removed (tasks are done/merged):
- git worktree remove ../myproject-worktrees/task-1.4-setup-cicd

Or clean up all finished worktrees:
- git worktree prune
```

### 8. Handle Edge Cases

- **No VK project**: Tell the user to run `/generate-tasks` first.
- **No tasks in progress**: Report that nothing is active. Suggest `/work-next` or `/work-parallel`.
- **No development plan**: Work from VK tasks only. Note that epic context and acceptance criteria are unavailable.
- **Git worktree command unavailable**: Skip worktree detection. Report VK status only.
- **Worktrees exist without matching VK tasks**: Flag as orphaned worktrees that may need cleanup.
