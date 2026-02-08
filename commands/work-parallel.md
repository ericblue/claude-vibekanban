---
description: Analyze backlog, identify independent tasks, set up worktrees, and launch parallel sessions
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task, mcp__vibe_kanban__list_repos
version: 0.3.1-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Work on Tasks in Parallel (Experimental)

> **This command is experimental and actively evolving.** The parallel execution model is being tested and refined. Expect changes.

## Context

You are setting up parallel task execution using git worktrees. Each task gets its own worktree directory and branch, and a full Claude Code session runs in each. This provides complete file isolation while allowing multiple tasks to be implemented simultaneously.

Full Claude Code sessions (not subagents) are required because each session needs MCP server access to communicate with VibeKanban.

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

`/work-parallel` supports two invocation modes:

**Explicit mode** -- user provides task IDs:

```
/work-parallel 1.3 2.1 3.2
```

Parse the provided IDs and look them up in the plan and VK. Skip to step 4 (dependency validation) with these tasks as the candidate set.

**Recommended mode** -- no task IDs provided:

```
/work-parallel
```

Analyze the backlog to identify tasks that can safely run in parallel:

1. Find all **available** tasks: status is `todo` in VK, all dependencies are `done`
2. Build a dependency graph and identify tasks with **no mutual dependencies** -- two tasks are safe to parallelize only if neither depends on the other, directly or transitively
3. Check for **file overlap risk**: tasks within the same epic or feature area are more likely to touch shared files. Flag these as higher risk.
4. Rank candidate groups by the same criteria as `/next-task`: priority, complexity, epic order, unblocking potential
5. Propose the top candidates, up to the default cap of **3 tasks**

### 4. Validate Independence

For each task in the candidate set, verify:

- **Dependencies satisfied**: all `Depends On` tasks are `done` in VK
- **No mutual dependencies**: no candidate task depends on another candidate task
- **VK-only task warning**: if a task was created directly in VK (not in the plan), it lacks dependency information. Warn the user: "Task [title] has no dependency data -- cannot verify it's safe to parallelize. Include anyway?"

If any validation fails, explain the issue and suggest removing the problematic task from the set.

### 5. Present for Review

Show the proposed set to the user for review and adjustment:

```
## Parallel Execution Plan

### Tasks to run (3 of 5 available)

| # | Task ID | Title | Priority | Complexity | Branch |
|---|---------|-------|----------|------------|--------|
| 1 | 2.3 | Add user API | High | M | task/2.3-add-user-api |
| 2 | 3.1 | Setup database | High | S | task/3.1-setup-database |
| 3 | 4.2 | Add logging | Medium | S | task/4.2-add-logging |

### Also available (not included)
- 3.3 - Add notifications (Medium, M)
- 5.1 - Write unit tests (Low, S)

### Warnings
- None (all tasks have dependency data and no mutual dependencies)

### Resource estimate
- 3 parallel Claude Code sessions
- 3 git worktrees in ../myproject-worktrees/

Adjust this set? You can:
- Remove tasks by number (e.g., "remove 3")
- Add tasks from the available list (e.g., "add 3.3")
- Change the count (e.g., "just run 2")

Or confirm to proceed.
```

**Do not create any worktrees or launch any sessions until the user explicitly confirms.**

### 6. Set Up Worktrees

After user confirmation, create the worktree infrastructure:

1. Determine the project name from the current directory name
2. Create the worktrees directory: `mkdir -p ../<project-name>-worktrees`
3. For each approved task, create a worktree and branch:

```bash
git worktree add ../<project-name>-worktrees/<branch-name> -b <branch-name>
```

**Branch naming convention:**

| Task source | Branch name |
|-------------|-------------|
| Plan task `2.3` titled "Add user API" | `task/2.3-add-user-api` |
| VK-only task titled "Fix login bug" | `task/fix-login-bug` (slugified title) |
| Ambiguous or untitled VK task | `task/<first-8-chars-of-vk-uuid>` |

Slugify titles by: lowercasing, replacing spaces with hyphens, removing special characters, truncating to 50 characters.

4. Report the created worktrees:

```
## Worktrees Created

| Task | Branch | Path |
|------|--------|------|
| 2.3 - Add user API | task/2.3-add-user-api | ../myproject-worktrees/task-2.3-add-user-api/ |
| 3.1 - Setup database | task/3.1-setup-database | ../myproject-worktrees/task-3.1-setup-database/ |
| 4.2 - Add logging | task/4.2-add-logging | ../myproject-worktrees/task-4.2-add-logging/ |
```

### 7. Mark Tasks In Progress

Before launching sessions, mark each approved task as `inprogress` in VibeKanban using `update_task`. This matches the `/work-task` pattern where tasks are marked before execution begins.

For each approved task, call `update_task` with status `inprogress`. Report results in a table:

```
## Task Status Updates

| Task | VK Status | Result |
|------|-----------|--------|
| 2.3 - Add user API | inprogress | Updated |
| 3.1 - Setup database | inprogress | Updated |
| 4.2 - Add logging | inprogress | Updated |
```

**Non-blocking on failure:** If a status update fails for a task, warn the user but continue with the remaining tasks and session launch. Example: "Warning: Failed to mark task 4.2 as inprogress in VK (API error). The session will still launch -- the agent can update the status itself."

### 8. Address Permissions

Before launching sessions, discuss permissions with the user. Parallel sessions need to run with minimal interruption -- permission prompts that block on user input will stall sessions.

Ask the user which approach they prefer:

```
## Permissions for Parallel Sessions

Parallel sessions need permission to use tools (Bash, file editing, MCP calls) without blocking.
How would you like to handle this?

1. **Bypass permissions** (recommended for headless) - Sessions bypass all permission checks.
   Each session runs with: `--permission-mode bypassPermissions`

2. **Don't ask mode** - Sessions auto-accept without prompting but log decisions.
   Each session runs with: `--permission-mode dontAsk`

3. **Skip permissions** - Legacy flag, same effect as bypass. Fastest but least safe.
   Each session runs with: `--dangerously-skip-permissions`

4. **Interactive** (manual terminals only) - Normal permission prompts in each terminal.
   You'll need to monitor and respond in each terminal window.

5. **Pre-configured settings** - Use your existing ~/.claude/settings.json allowedTools.
   Sessions will only prompt for tools not in your allowlist.
```

Notes:
- **Agent Teams**: Teammates inherit the lead's permission mode. Set the lead's mode before spawning teammates.
- **Headless `claude -p`**: Non-interactive -- **cannot respond to prompts**. Must use option 1, 2, 3, or 5.
- **Manual terminals**: Any option works, but option 4 requires active monitoring of all terminals.
- **Valid `--permission-mode` values**: `acceptEdits`, `bypassPermissions`, `default`, `delegate`, `dontAsk`, `plan`.

### 9. Launch Sessions

Launch Claude Code sessions in each worktree. The launch mechanism depends on what's available:

**Option A: Agent Teams (preferred if available)**

If Claude Code Agent Teams is enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`), suggest:

```
Create an agent team with 3 teammates. Each teammate should work in a separate worktree:
- Teammate 1: cd to ../myproject-worktrees/task-2.3-add-user-api/ and implement task 2.3 (Add user API). Acceptance criteria: [list AC]. When done, use get_task to read the current task description, then update_task to append a Completion Log (agent name, branch, files changed, summary, assumptions, AC checklist) to the description. Then mark as inreview in VK.
- Teammate 2: cd to ../myproject-worktrees/task-3.1-setup-database/ and implement task 3.1 (Setup database). Acceptance criteria: [list AC]. When done, use get_task to read the current task description, then update_task to append a Completion Log to the description. Then mark as inreview in VK.
- Teammate 3: cd to ../myproject-worktrees/task-4.2-add-logging/ and implement task 4.2 (Add logging). Acceptance criteria: [list AC]. When done, use get_task to read the current task description, then update_task to append a Completion Log to the description. Then mark as inreview in VK.
```

Note: The lead's permission mode propagates to all teammates. If the lead uses `--dangerously-skip-permissions`, all teammates do too.

**Tip:** For per-task quality gates, consider configuring Claude Code `TaskCompleted` hooks to run tests automatically when each teammate finishes. See the cookbook recipe "Quality gates with TaskCompleted hooks" in `docs/cookbook.md` for details.

**Option B: Auto-launched sessions (screen/tmux/background)**

Detect and use the best available session manager at runtime. Check in order: `which screen` -> `which tmux` -> fallback to background processes with log files.

Include the permission flag the user chose in step 8.

**Prompt template for all headless sessions:**

The `claude -p` prompt for each task should include the full task context (description, acceptance criteria, relevant PRD sections) and end with:

> "If you encounter ambiguity, make your best judgment and note assumptions. When you finish implementation, before marking the task as `inreview`:
>
> 1. Use `get_task` to read the current task description.
> 2. Use `update_task` to set the description to the original description plus a completion log section appended at the end. The completion log should include: files changed, a brief summary of what was implemented, any assumptions made, and whether acceptance criteria were met. Use this format:
>
> ```
> ---
> ## Completion Log
> **Agent:** Claude Code (headless)
> **Branch:** task/2.3-add-user-api
>
> ### Changes
> - Created src/routes/users.ts (new file)
> - Modified src/app.ts (added user routes)
> - Created tests/users.test.ts (new file)
>
> ### Summary
> Implemented CRUD endpoints for user management...
>
> ### Assumptions
> - Used JWT for authentication (not specified in AC)
>
> ### Acceptance Criteria
> - [x] GET /users/:id returns user profile
> - [x] PUT /users/:id updates user fields
> - [x] Endpoints require valid JWT
> - [x] Input validation rejects malformed data
> ```
>
> 3. Then use `update_task` to set status to `inreview`.
>
> If `update_task` fails when appending the completion log, warn but continue — log the error and proceed to mark the task as `inreview`. Logging is best-effort; it should never block the workflow.
>
> If you are completely blocked and cannot make progress, mark the task as inreview with a description of what's blocking you."

**Session naming convention:** `claude-task-<plan-id>` (e.g., `claude-task-2.3`). This mirrors the branch/worktree naming for easy cross-reference.

**Log files:** Always create log files at `../<project>-worktrees/task-<id>.log` regardless of launch mechanism. Screen uses its built-in `-L -Logfile` flag for logging (avoids pipe buffering). Tmux uses `pipe-pane`. Background mode redirects directly.

**Important: Do NOT pipe `claude -p` output through `tee`.** Piping changes stdout from a terminal (PTY) to a pipe, which triggers block buffering — output accumulates in 4KB chunks and the screen session appears blank. Instead, use the session manager's native logging so `claude -p` sees a real terminal and line-buffers normally.

**If `screen` is available:**

Launch each session inside a detached screen session using screen's built-in logging (`-L -Logfile`) and a wrapper script that detects failures and provides interactive recovery:

```bash
screen -dmS claude-task-2.3 -L -Logfile ../<project>-worktrees/task-2.3.log bash -c '
  cd ../<project>-worktrees/task-2.3-add-user-api
  claude -p "<prompt>" --permission-mode bypassPermissions 2>&1
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "SESSION_STATUS: FAILED (exit code $EXIT_CODE)"
    echo "================================================"
    echo "Session exited with error (code $EXIT_CODE)."
    echo "Launching interactive Claude for recovery."
    echo "Attach with: screen -r claude-task-2.3"
    echo "================================================"
    claude
  else
    echo ""
    echo "SESSION_STATUS: COMPLETED"
  fi
'
```

The wrapper pattern:
1. Screen's `-L -Logfile` captures all output to the log file natively — no pipe needed
2. `claude -p` sees a real terminal (screen's PTY) as stdout, so output appears immediately when you attach
3. Checks the exit code after `claude -p` finishes
4. On failure (non-zero exit): automatically launches interactive `claude` in the same screen session and worktree — the user just needs to attach to continue
5. On success (exit 0): the screen session ends cleanly

**Note on `-Logfile` compatibility:** If your version of screen doesn't support `-Logfile` (older system versions), use `-L` alone — the log will be written to `screenlog.0` in the working directory. Alternatively, install a newer screen via your package manager.

**Health check via `screen -ls`:** Session gone = completed successfully. Session still alive after expected completion time = either still running or waiting in interactive recovery mode for the user.

Note: During normal `claude -p` execution, the screen session is observe-only when attached (you can watch but not interact). On failure, the interactive fallback accepts full input.

**If `tmux` is available (and screen is not):**

Same wrapper pattern using tmux, with `pipe-pane` for logging:

```bash
tmux new-session -d -s claude-task-2.3 bash -c '
  cd ../<project>-worktrees/task-2.3-add-user-api
  claude -p "<prompt>" --permission-mode bypassPermissions 2>&1
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "SESSION_STATUS: FAILED (exit code $EXIT_CODE)"
    echo "================================================"
    echo "Session exited with error (code $EXIT_CODE)."
    echo "Launching interactive Claude for recovery."
    echo "Attach with: tmux attach -t claude-task-2.3"
    echo "================================================"
    claude
  else
    echo ""
    echo "SESSION_STATUS: COMPLETED"
  fi
'
tmux pipe-pane -t claude-task-2.3 "cat >> ../<project>-worktrees/task-2.3.log"
```

**Fallback (no screen or tmux):**

Run sessions as background processes with log file redirection. No interactive recovery is available in this mode:

```bash
cd ../<project>-worktrees/task-2.3-add-user-api && (claude -p "<prompt>" --permission-mode bypassPermissions 2>&1; EXIT_CODE=$?; if [ $EXIT_CODE -ne 0 ]; then echo "SESSION_STATUS: FAILED (exit code $EXIT_CODE)"; else echo "SESSION_STATUS: COMPLETED"; fi) > ../<project>-worktrees/task-2.3.log 2>&1 &
```

Warn the user: "Neither screen nor tmux was found. Sessions will run as background processes. You can monitor progress via log files (`tail -f ../<project>-worktrees/task-2.3.log`) but cannot attach to sessions interactively. Consider installing screen or tmux for a better experience."

**After launching all sessions, print a summary table:**

```
## Sessions Launched

| Task | Session | Log File | Attach Command |
|------|---------|----------|----------------|
| 2.3 - Add user API | claude-task-2.3 | ../<project>-worktrees/task-2.3.log | screen -r claude-task-2.3 |
| 3.1 - Setup database | claude-task-3.1 | ../<project>-worktrees/task-3.1.log | screen -r claude-task-3.1 |
| 4.2 - Add logging | claude-task-4.2 | ../<project>-worktrees/task-4.2.log | screen -r claude-task-4.2 |
```

(Adjust the "Attach Command" column for tmux or "(background -- use tail -f on log)" for the fallback.)

**Option C: Manual terminals**

Provide instructions for the user to open separate terminals:

```
Open 3 terminal windows and run `claude` in each worktree:

Terminal 1: cd ../myproject-worktrees/task-2.3-add-user-api && claude
Terminal 2: cd ../myproject-worktrees/task-3.1-setup-database && claude
Terminal 3: cd ../myproject-worktrees/task-4.2-add-logging && claude

In each session, use /work-task [task-id] to start the task.
```

Note: With manual terminals, you can respond to permission prompts interactively, but you'll need to monitor all terminal windows.

### 10. Provide Post-Execution Guidance

After launching sessions, remind the user about monitoring and the review-before-merge workflow:

```
## Next Steps

1. **Health check**: Run `screen -ls` (or `tmux list-sessions`) to see active sessions.
   - Session listed = still running (or in interactive recovery mode)
   - Session gone = completed successfully
2. **Observe**: Attach to a running session to watch progress:
   - `screen -r claude-task-2.3` (Ctrl-A D to detach without stopping)
   - `tmux attach -t claude-task-2.3` (Ctrl-B D to detach)
3. **Monitor status**: Check `/session-status` or `/plan-status` for a unified view
4. **Review**: When tasks move to `inreview`, test each branch:
   - cd into the worktree, run tests, verify behavior
   - Use VK's diff view and inline commenting for code review
5. **Merge and clean up**: Run `/merge-parallel` to merge all ready branches, run tests, update VK status, and clean up worktrees and sessions in one step
6. **Sync**: Run `/sync-plan` after all branches are merged
```

### 11. Handle Edge Cases

- **No available tasks**: All tasks are done, in progress, or blocked. Report what's blocking progress.
- **Only 1 available task**: Suggest using `/work-next` instead -- parallelism adds overhead with no benefit for a single task.
- **No development plan**: Check VK directly for tasks. Warn that dependency analysis is not possible without a plan.
- **No VK project**: Tell the user to run `/generate-tasks` first.
- **Worktree already exists**: If a worktree/branch already exists for a task, inform the user and ask whether to reuse it or create a fresh one.
- **User wants more than 3**: Allow it, but warn about resource consumption: "Each session consumes tokens and local compute. Running [N] parallel sessions will use significantly more resources than the default 3."
- **Git worktree command fails**: Check if the branch name already exists (`git branch --list`). If so, suggest a different name or ask the user to delete the stale branch.
