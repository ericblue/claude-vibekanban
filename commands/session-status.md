---
description: Check status of all active work across local worktrees and VK sessions
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task
version: 0.5-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Session & Worktree Status (Experimental)

> **This command is experimental and actively evolving.** Expect changes.

## Context

You are checking the status of all active work -- both local parallel sessions (Tier 1 worktrees from `/work-parallel`) and remote delegated sessions (Tier 2 VK workspace sessions from `/delegate-task` or `/delegate-parallel`). This gives the user a unified snapshot across all execution mechanisms.

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

### 3.5 Check for Screen/Tmux Sessions

Check for active screen or tmux sessions that match the `claude-task-*` naming convention used by `/work-parallel`:

1. Run `screen -ls` and parse output for sessions matching `claude-task-*`. Extract session names and state (Attached/Detached).
2. If no screen sessions found, fall back to `tmux list-sessions` and parse for `claude-task-*` sessions.
3. Match session names to tasks: session `claude-task-2.3` maps to plan task 2.3.
4. Record session state for each matched task:
   - **Attached** -- someone is currently watching/interacting with the session
   - **Detached** -- session is running unattended (normal for `claude -p`)
   - **No session found** -- session completed (exited cleanly) or was never launched via screen/tmux

### 3.6 Determine Completion Status

Cross-reference session state, VK status, and log files to determine a completion heuristic for each task:

| Session State | VK Status | Log Evidence | Completion Status |
|---------------|-----------|--------------|-------------------|
| No session | `inreview` or `done` | Log exists | **Completed** -- session finished normally |
| No session | `inprogress` | Log ends with `SESSION_STATUS: FAILED` or error | **Failed** -- session crashed or errored |
| No session | `inprogress` | Log ends with `SESSION_STATUS: COMPLETED` | **Completed** -- session finished but didn't update VK |
| No session | `inprogress` | No log or log has no status marker | **Unknown** -- may have completed or crashed without logging |
| Detached | `inprogress` | Log file growing (modified recently) | **Running** -- session is actively working |
| Detached | `inprogress` | Log file stale (not modified in 10+ min) | **Possibly stuck** -- may need investigation |
| Detached | `inreview` or `done` | Any | **Completed (session lingering)** -- work done, session still alive (possibly in recovery mode) |
| Attached | Any | Any | **Active** -- someone is observing or interacting |

To check for `SESSION_STATUS:` markers in log files:

```bash
tail -5 ../<project>-worktrees/task-<id>.log 2>/dev/null | grep "SESSION_STATUS:"
```

Valid markers (written by `/work-parallel` wrapper scripts):
- `SESSION_STATUS: COMPLETED` -- session finished successfully
- `SESSION_STATUS: FAILED (exit code N)` -- session exited with an error

Include the "Completion" column in the status tables below.

### 4. Present the Status Report

```
## Active Sessions

### In Progress (3 tasks)

| Task | Status | Type | Location | Session | Completion |
|------|--------|------|----------|---------|------------|
| 2.3 - Add user API | inprogress | Worktree | ../myproject-worktrees/task-2.3-add-user-api/ | `screen -r claude-task-2.3` (Detached) | Running |
| 3.1 - Setup database | inprogress | VK Workspace | Remote (CLAUDE_CODE) | (no session found) | Unknown |
| 4.2 - Add logging | inprogress | Worktree | ../myproject-worktrees/task-4.2-add-logging/ | `screen -r claude-task-4.2` (Detached) | Running |

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

**Check for `SESSION_STATUS:` markers** in log files to determine definitive completion:

```bash
tail -5 ../<project>-worktrees/task-<id>.log 2>/dev/null | grep "SESSION_STATUS:"
```

If a log file contains `SESSION_STATUS: COMPLETED`, the session finished successfully (even if VK wasn't updated). If it contains `SESSION_STATUS: FAILED (exit code N)`, the session errored. Use these markers to refine the completion heuristic from step 3.6.

Report this as a "Session Activity" section:

```
### Session Activity

| Task | Branch | Last Commit | Log File | Session Status |
|------|--------|------------|----------|----------------|
| 2.3 - Add user API | task/2.3-add-user-api | 3 min ago: "Add user endpoint" | task-2.3.log (active) | screen: Detached |
| 3.1 - Setup database | task/3.1-setup-database | 8 min ago: "Add schema migration" | task-3.1.log (active) | screen: Detached |
| 4.2 - Add logging | task/4.2-add-logging | (no commits yet) | No log file | (no session) |
```

If a task has no commits, no log activity, and no active screen/tmux session, flag it as potentially failed:

```
⚠ Task 4.2 has no commits, no log activity, and no active session. The session may have failed to launch or crashed.
  - Check the log file for errors: tail -20 ../<project>-worktrees/task-4.2.log
  - If using screen/tmux: session gone = completed or crashed. Check VK status.
  - If using Agent Teams: ask the lead about teammate status
  - If using manual terminals: switch to that terminal to check
```

### 6. Suggest Actions

Based on the status, suggest relevant next steps:

- **Tasks in review**: "Task 1.4 is ready for review. Open it in VK to see the diff, or cd into the worktree to test."
- **Blocked tasks about to unblock**: "When task 2.3 completes, task 2.4 will be ready to start."
- **No active work**: "No tasks are in progress. Run `/work-next` to start the next task, or `/work-parallel` for parallel execution."
- **Many tasks in review**: "You have [N] tasks waiting for review. Consider reviewing and merging them before starting more work."
- **Multiple tasks ready to merge**: If 2+ tasks are `inreview` or `done` with active worktrees, suggest: "Multiple tasks are ready to merge. Run `/merge-parallel` to merge, test, and clean up all branches at once."
- **Stale in-progress tasks**: If tasks have been `inprogress` without a corresponding worktree or active session, flag them: "Task [X] is marked in progress but has no active worktree or session. It may be stale."
- **Active screen/tmux session, observe progress**: "Task 2.3 has an active screen session. Attach to observe: `screen -r claude-task-2.3` (Ctrl-A D to detach)."
- **Session ended but task still inprogress**: "Task 4.2 has no active screen session but is still `inprogress` in VK. The session may have completed without updating VK, or it may have crashed. Check the log file (`tail -20 ../<project>-worktrees/task-4.2.log`) and either relaunch or update the task status manually."
- **Session in interactive recovery**: "Task 3.1 has a screen session still alive well after expected completion. It may be in interactive recovery mode (agent failed and relaunched interactively). Attach to continue: `screen -r claude-task-3.1`."

### 7. Provide Cleanup Guidance

If there are worktrees for completed or merged tasks:

```
### Cleanup Available

These worktrees can be removed (tasks are done/merged):
- git worktree remove ../myproject-worktrees/task-1.4-setup-cicd

Or clean up all finished worktrees:
- git worktree prune
```

For tasks in `inreview` or `done` that haven't been merged yet, suggest: "Consider running `/merge-parallel` to merge branches, update VK, and clean up worktrees in one step."

### 8. Handle Edge Cases

- **No VK project**: Tell the user to run `/generate-tasks` first.
- **No tasks in progress**: Report that nothing is active. Suggest `/work-next` or `/work-parallel`.
- **No development plan**: Work from VK tasks only. Note that epic context and acceptance criteria are unavailable.
- **Git worktree command unavailable**: Skip worktree detection. Report VK status only.
- **Worktrees exist without matching VK tasks**: Flag as orphaned worktrees that may need cleanup.
