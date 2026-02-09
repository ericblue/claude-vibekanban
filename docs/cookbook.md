# Cookbook

Practical recipes, walkthroughs, and answers to common questions for using the VibeKanban slash command workflow.

---

## Table of Contents

- [Quick Start Guides](#quick-start-guides)
- [End-to-End Walkthroughs](#end-to-end-walkthroughs)
- [Common Recipes](#common-recipes)
- [Tips and Best Practices](#tips-and-best-practices)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)

---

## Quick Start Guides

### Starting from scratch (just an idea)

```
/generate-prd
```

You'll be interviewed in 3 rounds about your project. Answer the questions, and a PRD is written to `docs/prd.md`. Then continue with:

```
/prd-review
/create-plan
/generate-tasks
/work-next
```

### Starting with an existing PRD

If you already have a `docs/prd.md`:

```
/prd-review        # analyze gaps, suggest epics
/create-plan       # generate the development plan
/generate-tasks    # create VibeKanban tasks
/work-next         # start working
```

### Starting with an existing plan

If you already have `docs/development-plan.md` with tasks:

```
/generate-tasks    # create VK tasks and link them
/work-next         # start working
```

### Just want to start coding

If your plan and VK tasks are already set up:

```
/work-next         # picks the best task and executes it
```

Run `/work-next` repeatedly to work through the backlog.

### Want to run multiple tasks in parallel (experimental)

If you have independent tasks ready to go:

```
/work-parallel             # LLM analyzes backlog and proposes candidates
```

Or specify tasks explicitly:

```
/work-parallel 2.3 3.1 4.2
```

Review the proposed set, adjust if needed, confirm, and parallel sessions launch in isolated git worktrees.

After sessions complete, merge everything back:

```
/merge-parallel            # merge branches, test, update VK, clean up
```

### Want to delegate tasks to remote agents (experimental)

Hand off a task to a VibeKanban workspace session:

```
/delegate-task 2.3         # delegates task 2.3 to a VK session
```

Or delegate multiple independent tasks at once:

```
/delegate-parallel 2.3 3.1 4.2
```

---

## End-to-End Walkthroughs

### Walkthrough: Building a new feature from idea to done

**Step 1: Generate the PRD**

```
/generate-prd I want to build a REST API for managing a personal book library
```

Claude asks 3 rounds of questions about scope, users, technical constraints, and success criteria. After answering, `docs/prd.md` is created.

**Step 2: Review the PRD**

```
/prd-review
```

Claude reads the PRD, identifies gaps (missing error handling spec? unclear auth requirements?), suggests an epic breakdown, and asks clarifying questions. Answer them to refine the PRD.

**Step 3: Create the development plan**

```
/create-plan
```

Claude generates `docs/development-plan.md` with:
- Epics (Foundation, Core Features, Supporting Features, etc.)
- Tasks with IDs (1.1, 1.2, 2.1, ...)
- Priority, complexity, and dependency info per task
- Acceptance criteria per task and per epic

**Step 4: Generate VibeKanban tasks**

```
/generate-tasks
```

Claude creates a task in VibeKanban for each plan task and links them with `<!-- vk:ID -->` comments in the plan file. Your VK board is now populated.

**Step 5: Work through the backlog**

```
/work-next
```

Claude identifies the best available task (dependencies met, high priority, small complexity), presents it with acceptance criteria, and asks for confirmation. After you confirm:

1. Task is marked `inprogress` in VK
2. Claude implements the task with full context (PRD + plan + AC + codebase)
3. Each acceptance criterion is verified
4. You're asked to mark it `done` or `inreview`

Repeat `/work-next` to keep going.

**Step 6: Sync periodically**

```
/sync-plan
```

Updates the plan file to match VK status. Run this after completing a batch of tasks to keep everything aligned.

**Step 7: Close completed epics**

```
/close-epic Foundation
```

Verifies all tasks in the epic are done, checks acceptance criteria, and marks the epic as COMPLETE in the plan.

---

### Walkthrough: Picking up a specific task

Sometimes you know exactly what you want to work on.

**By plan task ID:**

```
/work-task 2.3
```

**By title (fuzzy match):**

```
/work-task implement auth
```

**By browsing:**

```
/work-task
```

With no argument, Claude lists available tasks and lets you pick.

---

### Walkthrough: Adding scope mid-project

You realize you need a new epic for analytics that wasn't in the original plan.

```
/add-epic
```

Claude asks for:
- Epic name ("Analytics Dashboard")
- Description
- Tasks (or add them later)
- Where to insert it (after which epic)

The plan is updated with the new epic, subsequent epics are renumbered, and task IDs are updated. Then:

```
/generate-tasks    # create VK tasks for the new epic
```

---

### Walkthrough: Checking progress without changing anything

```
/plan-status
```

Shows a read-only progress report with:
- Overall completion percentage
- Per-epic progress bars
- Recently completed tasks
- Currently in-progress tasks
- High-priority next tasks
- Warnings (unlinked tasks, stale sync)

Nothing is modified. Safe to run anytime.

---

### Walkthrough: Running tasks in parallel (Tier 1 -- local worktrees)

You have several independent tasks ready and want to knock them out faster.

> **Real-world example:** The [Parallel Task Execution Walkthrough](parallel-task-execution-walkthrough.md) shows this full workflow in action on a retro BBS project -- 3 tasks across different epics running concurrently via `/work-parallel`, monitored with `/session-status`, and merged back with `/merge-parallel`. Includes screenshots of every step from backlog analysis through merge.

**Step 1: Identify candidates**

```
/work-parallel
```

Claude reads the plan, fetches VK status, and identifies tasks with no mutual dependencies. It proposes up to 3 candidates:

```
## Parallel Execution Plan

### Tasks to run (3 of 5 available)

| # | Task ID | Title | Priority | Complexity | Branch |
|---|---------|-------|----------|------------|--------|
| 1 | 2.3 | Add user API | High | M | task/2.3-add-user-api |
| 2 | 3.1 | Setup database | High | S | task/3.1-setup-database |
| 3 | 4.2 | Add logging | Medium | S | task/4.2-add-logging |
```

**Step 2: Adjust and confirm**

Review the set. You can remove tasks ("remove 3"), add others ("add 3.3"), or change the count ("just run 2"). Nothing happens until you confirm.

**Step 3: Choose permissions**

Claude asks how parallel sessions should handle permissions:

- **Auto-accept** (recommended) -- sessions accept all tool calls
- **Skip permissions** -- no permission checks at all
- **Interactive** -- normal prompts in each terminal (manual terminals only)
- **Pre-configured** -- use your existing `~/.claude/settings.json` allowlist

**Step 4: Worktrees are created**

After confirmation, Claude creates git worktrees:

```
~/Development/
  myproject/                              # your main directory
  myproject-worktrees/
    task-2.3-add-user-api/
    task-3.1-setup-database/
    task-4.2-add-logging/
```

**Step 5: Tasks marked in progress and sessions auto-launch**

Claude marks all approved tasks as `inprogress` in VibeKanban, then auto-launches sessions. It detects whether `screen` or `tmux` is available at runtime:

- **Screen/tmux found**: Sessions launch inside managed screen/tmux sessions with failure recovery. You'll see a summary table with session names, log paths, and attach commands.
- **Neither found**: Sessions run as background processes with log file output.
- **Agent Teams**: If enabled, teammates are spawned instead.
- **Manual terminals**: You launch `claude` in each worktree yourself.

```
## Sessions Launched

| Task | Session | Log File | Attach Command |
|------|---------|----------|----------------|
| 2.3 - Add user API | claude-task-2.3 | ../myproject-worktrees/task-2.3.log | screen -r claude-task-2.3 |
| 3.1 - Setup database | claude-task-3.1 | ../myproject-worktrees/task-3.1.log | screen -r claude-task-3.1 |
| 4.2 - Add logging | claude-task-4.2 | ../myproject-worktrees/task-4.2.log | screen -r claude-task-4.2 |
```

**Step 6: Monitor and review**

Check progress with `/session-status` or use screen/tmux commands directly:

```bash
screen -ls                           # list all sessions (health check)
screen -r claude-task-2.3            # attach to observe (Ctrl-A D to detach)
tail -f ../myproject-worktrees/task-2.3.log   # watch log file
```

When tasks move to `inreview`, `cd` into each worktree to review, test, and merge branches back to main sequentially.

**Step 7: Merge and clean up**

When tasks are in `inreview` or `done`, merge all branches back to main:

```
/merge-parallel
```

This merges branches sequentially, optionally runs tests after each merge, updates VK status to `done`, and offers to clean up worktrees, branches, and sessions. If a conflict occurs, resolve it and re-run -- already-merged branches are skipped.

For manual merging, see the "Merging parallel branches safely" recipe below.

---

### Walkthrough: Delegating tasks to VK workspace sessions (Tier 2)

You want to hand off a task to a separate agent session managed by VibeKanban.

**Single task delegation:**

```
/delegate-task 2.3
```

Claude looks up task 2.3, asks which agent you'd like to use (Claude Code, Cursor, Codex, Gemini, Copilot, DROID), identifies the repo and branch, and calls `start_workspace_session` to launch the remote session.

**Batch delegation:**

```
/delegate-parallel 2.3 3.1 4.2
```

Same as above, but for multiple tasks at once. Claude verifies independence (no mutual dependencies), asks for the executor type (same for all tasks in a batch), and launches all sessions.

**Monitoring:**

Track progress in the VK UI or with `/session-status`. When the remote agent finishes, the task moves to `inreview`. Open it in VK to see the full diff, leave inline comments, or send revision requests.

**Merging:**

Use VK's one-click merge to merge the branch to main. The task automatically moves to `done`. Then run `/sync-plan` to update the plan file.

---

### Walkthrough: Monitoring parallel work

You've launched 3 parallel sessions and want to know what's happening.

```
/session-status
```

This shows:
- **VK task status** -- which tasks are `inprogress`, `inreview`, or `done`
- **Local worktrees** -- detected via `git worktree list`, matched to tasks
- **Git activity** -- recent commits in each worktree as a progress proxy
- **Log files** -- for headless sessions that redirect output to files
- **Blocked tasks** -- tasks waiting on the in-progress work to finish
- **Cleanup suggestions** -- worktrees for completed tasks that can be removed

For real-time monitoring of individual sessions, see the [observability FAQ](#parallel-execution-experimental).

---

## Common Recipes

### Recipe: Review-before-merge workflow (recommended for parallel tasks)

When tasks run on feature branches (Tier 1 worktrees or Tier 2 VK workspaces), always review before merging to main. This is the human-in-the-loop step that keeps quality high.

**For Tier 2 (VK workspace sessions):**

VibeKanban provides this workflow natively in its UI:

1. Agent finishes work and task moves to `inreview`
2. Open the task in VK to see the full diff and agent session history
3. Leave inline comments on specific lines of code
4. Send revision requests -- VK starts a new agent session in the same feature branch, with full conversation history
5. Repeat until satisfied
6. Test the branch: open it in your IDE, run the dev server, verify behavior
7. Click merge in VK -- branch merges to main, task moves to `done`

**For Tier 1 (local worktrees):**

Worktrees are created under `../<project-name>-worktrees/`:

```
~/Development/
  myproject/                              # main working directory
  myproject-worktrees/
    task-2.3-add-user-api/                # worktree for task 2.3
    task-3.1-setup-database/              # worktree for task 3.1
```

1. The Claude Code session in the worktree finishes and marks the task `inreview` via VK's MCP API
2. `cd` into the worktree directory and review the changes (`git diff`, run tests, start dev server)
3. If changes are needed, start a new Claude Code session in the worktree to revise
4. When satisfied, merge the branch to main and mark the task `done`
5. Clean up: `git worktree remove ../<project>-worktrees/task-2.3-add-user-api`

**Sequential merge order matters.** When multiple branches are ready:

1. Merge the first branch to main
2. Rebase the second branch onto main (since main moved forward)
3. Resolve any conflicts (shared files like registries, route tables, index files are common conflict points)
4. Merge the second branch
5. Repeat for remaining branches

This rebase-then-merge pattern is expected. Even well-separated tasks often touch shared files (component registries, config files, barrel exports). Plan for it.

### Recipe: Morning standup check

Start your day by seeing where things stand:

```
/plan-status       # overview of progress
/next-task         # see what's recommended
```

Then either start working:

```
/work-next         # execute the top recommendation
```

Or pick something specific:

```
/work-task 3.1     # work on a task you have in mind
```

### Recipe: End-of-session sync

After finishing work for the day:

```
/sync-plan
```

This updates the plan file to match VK, detects any drift, and gives you a clean state for tomorrow.

### Recipe: Reviewing what changed

After running `/sync-plan`, check the output for:

- **Stale in-progress tasks** -- tasks that have been `inprogress` for too long
- **Dependency violations** -- tasks started before their dependencies were done
- **Ready to start** -- tasks whose dependencies are now satisfied
- **Scope drift** -- tasks in the plan without VK IDs, or VK tasks not in the plan

### Recipe: Working on a task that's only in VibeKanban

`/work-task` can handle tasks that exist in VK but not in the plan. It will pull the task details from VK and implement based on that. You won't get plan-level acceptance criteria, but the VK task description is used as context.

### Recipe: Skipping a recommended task

If `/work-next` recommends a task you don't want to do right now:

```
/work-next
> [Claude recommends task 2.1]
> No, skip that one -- what else is available?
```

Claude will present the next candidates from its ranked list.

### Recipe: Handling unmet dependencies

If you start a task whose dependencies aren't complete:

```
/work-task 3.2
> Warning: task 3.2 depends on 2.1 (still inprogress) and 2.3 (todo)
> Proceed anyway?
```

You can proceed (at your own risk) or go back and work on the dependencies first.

### Recipe: Splitting a task that's too large

If a task turns out to be bigger than expected:

1. Work on what you can and mark it `inreview` instead of `done`
2. Use `/add-epic` or manually edit the plan to break the remaining work into smaller tasks
3. Run `/generate-tasks` to create VK tasks for the new entries
4. Run `/sync-plan` to reconcile

### Recipe: Recovering from a failed implementation

If `/work-task` produces code that doesn't work:

1. Don't mark the task as `done` -- leave it `inprogress`
2. Fix the issues in the same session or a new one
3. Re-verify the acceptance criteria
4. Then mark as `done`

The task stays `inprogress` in VK until you explicitly confirm completion.

### Recipe: Running parallel tasks with explicit IDs

When you already know which tasks to parallelize:

```
/work-parallel 2.3 3.1 4.2
```

This skips the analysis step and goes straight to dependency validation and the confirmation screen. Useful when you've already checked independence yourself.

### Recipe: Delegating to a different agent type

If a task is better suited to a different editor or agent:

```
/delegate-task 2.3
> Which executor? Cursor
```

VK launches a Cursor workspace session for task 2.3. The task status updates flow back to VK automatically. You can review in the VK UI when done.

### Recipe: Monitoring parallel sessions (screen/tmux)

When `/work-parallel` auto-launches sessions via screen or tmux, use these commands to monitor:

**List all sessions (health check):**

```bash
screen -ls                           # screen
tmux list-sessions                   # tmux
```

Sessions named `claude-task-*` are from `/work-parallel`. Session gone = completed. Session alive = still running or in interactive recovery.

**Attach to observe a running session:**

```bash
screen -r claude-task-2.3            # screen (Ctrl-A D to detach)
tmux attach -t claude-task-2.3       # tmux (Ctrl-B D to detach)
```

During normal `claude -p` execution, the session is observe-only. If the agent has failed and entered interactive recovery, you can type commands directly.

**Watch log files:**

```bash
tail -f ../myproject-worktrees/task-2.3.log          # watch live output
git -C ../myproject-worktrees/task-2.3-add-user-api log --oneline -5   # check commits
```

**Kill a session:**

```bash
screen -X -S claude-task-2.3 quit    # screen
tmux kill-session -t claude-task-2.3 # tmux
```

Or check all sessions at once with `/session-status`.

### Recipe: Debugging a stuck parallel session

If a session seems stuck or has failed:

**1. Check if the session is still alive:**

```bash
screen -ls | grep claude-task-2.3
```

- **Session listed (Detached)**: Still running normally, or in interactive recovery mode. Attach to check: `screen -r claude-task-2.3`
- **Session listed (Attached)**: Someone else is already connected to it.
- **No matching session**: Session exited (either completed successfully or crashed).

**2. If the session is alive, attach to investigate:**

```bash
screen -r claude-task-2.3
```

If you see the interactive recovery message ("Session exited with error...Launching interactive mode"), you're in interactive `claude` already positioned in the correct worktree. Continue the work from there.

If the session is still running `claude -p`, you can only observe -- wait for it to finish or kill the session to restart.

**3. If the session is gone but the task is still `inprogress` in VK:**

The session completed or crashed without updating VK. Check the log file:

```bash
tail -50 ../myproject-worktrees/task-2.3.log
```

Then either:
- Relaunch manually: `cd ../myproject-worktrees/task-2.3-add-user-api && claude` (interactive session to finish the work)
- Update VK status if the work was actually completed: use `update_task` to mark `inreview`

### Recipe: Using Agent Teams with this workflow

The most powerful parallel setup combines structured planning with Agent Teams coordination:

1. Plan and decompose: `/create-plan` then `/generate-tasks`
2. Identify parallel candidates: `/work-parallel` (review step -- don't confirm yet)
3. Note the task IDs and worktree paths from the proposed plan
4. Create worktrees manually or let `/work-parallel` create them
5. Spawn an Agent Team where each teammate works in a separate worktree:
   - Teammate 1: implement task 2.3 in `../myproject-worktrees/task-2.3-add-user-api/`
   - Teammate 2: implement task 3.1 in `../myproject-worktrees/task-3.1-setup-database/`
6. Teammates update VK via MCP as they work
7. After completion, run `/sync-plan` to reconcile

This gives you structured decomposition (this workflow) + real-time coordination (Agent Teams) + persistent tracking (VK).

### Recipe: Cleaning up after parallel work

After all parallel branches are merged to main:

```bash
# See all active worktrees
git worktree list

# Remove specific worktrees
git worktree remove ../myproject-worktrees/task-2.3-add-user-api
git worktree remove ../myproject-worktrees/task-3.1-setup-database

# Or remove everything at once
rm -rf ../myproject-worktrees/ && git worktree prune

# Sync the plan to reflect completed work
/sync-plan
```

### Recipe: Merging parallel branches safely

When multiple worktree branches are ready to merge:

1. Pick the branch least likely to conflict (simplest changes)
2. Merge it to main: `git merge task/4.2-add-logging`
3. Rebase the next branch onto the updated main:
   ```bash
   cd ../myproject-worktrees/task-2.3-add-user-api
   git rebase main
   ```
4. Resolve any conflicts (common in shared files: registries, configs, index files)
5. Merge the rebased branch to main
6. Repeat for remaining branches

**Tip:** Merge the smallest/most isolated branches first to minimize cascading conflicts.

### Recipe: Merging parallel branches with /merge-parallel

For an automated merge-test-cleanup cycle, use `/merge-parallel` instead of manual merging:

```
/merge-parallel
```

This command:
1. Detects all worktree branches and cross-references with VK status
2. Identifies merge-ready branches (`inreview` or `done`) and skips in-progress ones
3. Presents a merge plan sorted by simplest first (fewest commits)
4. Asks for an optional test command and merge strategy (merge or rebase)
5. Merges branches sequentially, stopping on conflicts
6. Updates VK task status to `done`
7. Offers to clean up worktrees, branches, and sessions

**When to use automated vs manual merging:**

| Scenario | Approach |
|----------|----------|
| Multiple branches ready, want speed | `/merge-parallel` |
| Need to cherry-pick specific commits | Manual merge |
| Expect complex conflicts requiring careful resolution | Manual merge (but `/merge-parallel` stops on conflicts too) |
| Want to test each branch individually before merging | Manual review first, then `/merge-parallel` |

**Tip:** Always run `/merge-parallel` from the main project directory, not from inside a worktree.

### Recipe: Quality gates with TaskCompleted hooks

Claude Code hooks can run scripts automatically in response to agent events. You can use this to add per-task quality gates that run tests when a session finishes its work.

**How hooks work:** Claude Code supports hooks that execute shell commands at defined points in the agent lifecycle. The `TaskCompleted` event fires when a subagent (teammate) finishes its assigned work.

**Example `.claude/settings.json` hook configuration:**

```json
{
  "hooks": {
    "TaskCompleted": [
      {
        "command": ".claude/quality-gate.sh"
      }
    ]
  }
}
```

**Example `quality-gate.sh` script:**

```bash
#!/bin/bash
# Run tests as a quality gate when a task completes
echo "Running quality gate..."

# Run your project's test suite
npm test 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "QUALITY GATE FAILED: Tests did not pass (exit code $EXIT_CODE)"
  exit 1
else
  echo "QUALITY GATE PASSED: All tests passing"
  exit 0
fi
```

**Two-tier quality gates with `/merge-parallel`:**

1. **Per-task gate (hook):** Each agent session runs tests on its own branch when it completes. Catches task-level regressions immediately.
2. **Integration gate (`/merge-parallel`):** After merging each branch to main, run the test command to catch cross-branch integration issues.

This gives you quality checks at both the individual task level and the integration level.

**Caveat:** The hooks configuration format may evolve with future Claude Code versions. Check the Claude Code documentation for the latest syntax.

### Recipe: Logging work results to VibeKanban

When tasks are executed locally (Tier 1 worktrees or interactive `/work-task`), VibeKanban has no built-in visibility into what happened — no session history, no diffs, no "Attempts" like Tier 2 workspace sessions provide. As a stopgap, the workflow appends a structured **Completion Log** to the task description in VK when work finishes.

**How it works:**

Before marking a task as `inreview` or `done`, the agent:

1. Calls `get_task` to read the current task description
2. Appends a `## Completion Log` section to the description
3. Calls `update_task` with the updated description
4. Then updates the task status

**What the Completion Log looks like in VK:**

```
Original task description here...

---
## Completion Log
**Agent:** Claude Code (headless)
**Branch:** task/2.3-add-user-api

### Changes
- Created src/routes/users.ts (new file)
- Modified src/app.ts (added user routes)
- Created tests/users.test.ts (new file)

### Summary
Implemented CRUD endpoints for user management with JWT auth.

### Assumptions
- Used JWT for authentication (not specified in AC)

### Acceptance Criteria
- [x] GET /users/:id returns user profile
- [x] PUT /users/:id updates user fields
- [x] Endpoints require valid JWT
- [x] Input validation rejects malformed data

### Merge Log
**Merged to:** main
**Strategy:** merge
**Test result:** All tests passed
**Commits merged:** 5
**Date:** 2026-02-07
```

The Completion Log section is added by the implementing agent (headless or interactive). The Merge Log subsection is added later by `/merge-parallel` when the branch is merged to main.

**Where logging happens:**

| Command | What's logged | Agent field |
|---------|---------------|-------------|
| `/work-parallel` (headless) | Completion Log (changes, summary, AC) | `Claude Code (headless)` |
| `/work-parallel` (Agent Teams) | Completion Log (changes, summary, AC) | `Claude Code (teammate)` |
| `/work-task` (interactive) | Completion Log (changes, summary, AC) | `Claude Code (interactive)` |
| `/merge-parallel` | Merge Log (strategy, test result, commits) | N/A (appended to existing log) |

**This is a stopgap.** The VK MCP API currently has no comment or activity log endpoint — `update_task` only supports `title`, `description`, and `status`. Appending to the description is the only way to persist structured results. A proper VK comment/log API would enable:

- Separate comments per attempt (instead of appending to description)
- Timestamped activity history
- Structured metadata (not embedded in markdown)
- Clean separation between task definition and execution history

Until that API exists, the description-append pattern provides basic visibility into what happened during local task execution.

**Non-blocking by design:** If the description update fails, the agent warns but continues. Logging should never block the workflow.

---

## Tips and Best Practices

### Plan management

- **Run `/sync-plan` before and after work sessions.** Before to get the latest state, after to record what you did.
- **Commit `docs/development-plan.md` to version control.** This gives you history of how the plan evolved.
- **Keep tasks atomic.** Each task should be completable in one session. If a task is complexity XL, consider breaking it up.
- **Write specific acceptance criteria.** "API works" is bad. "POST /users returns 201 with valid input and 400 with missing fields" is good. The more testable the AC, the better `/work-task` can verify.

### Execution

- **Let `/work-next` pick for you when possible.** Its scoring algorithm considers dependencies, priority, complexity, and unblocking potential -- it often makes better sequencing decisions than manual selection.
- **Use `/work-task` when you have a reason to override.** Maybe you're debugging a specific area, or a stakeholder needs a particular feature next.
- **Review the acceptance criteria check before marking done.** Claude verifies AC and reports results. If something is marked as "not verified" or "partially met", investigate before closing.
- **Default to `inreview` over `done` for parallel tasks.** When tasks run on feature branches, always mark as `inreview` first. Test the branch, review the diff, and only mark `done` after merging to main. This keeps the human-in-the-loop for quality control.
- **For sequential single-branch work, `done` is fine.** If you're working on main with `/work-next` one task at a time, marking `done` directly is reasonable since you're reviewing in real time.
- **Watch for shared file conflicts during parallel work.** Even when tasks are independent, they often touch shared files: component registries, route tables, barrel exports, config files. Expect merge conflicts in these and plan for the rebase-then-merge workflow.

### PRD and planning

- **Don't skip `/prd-review`.** The clarifying questions often surface requirements you forgot. Better to catch gaps before coding.
- **Include non-functional requirements in the PRD.** Performance targets, security requirements, accessibility -- these become acceptance criteria in the plan.
- **Use `/add-epic` for scope changes.** Don't manually hack the plan file. The command handles renumbering and keeps the format consistent.

### Parallel execution

- **Start with 2-3 parallel sessions, not 10.** Each session consumes tokens and local resources. Scale up only after you're comfortable with the workflow.
- **Always use `inreview`, never `done`, for parallel tasks.** Review each branch before merging. The `inreview` status is your quality gate.
- **Write detailed acceptance criteria.** Parallel sessions (especially headless) can't ask you questions. The more specific the AC, the less ambiguity the agent faces.
- **Merge branches one at a time.** Use the rebase-then-merge pattern. Even independent tasks often touch shared files (registries, configs, barrel exports).
- **Run `/session-status` instead of checking each session individually.** It gives you a unified view across worktrees and VK.
- **Redirect headless output to log files.** You'll want them for debugging when a session produces unexpected results.
- **Use the same executor for all tasks in a batch delegation.** `/delegate-parallel` applies one executor to all tasks. For mixed executors, use `/delegate-task` individually.
- **Clean up worktrees promptly after merging.** Stale worktrees consume disk space and clutter `git worktree list` output.
- **Don't run `/sync-plan` from multiple sessions simultaneously.** It modifies the plan file and isn't safe for concurrent writes. Run it once from your main directory after all branches are merged.

### VibeKanban integration

- **Don't manually edit VK task status outside the commands.** The commands expect VK to reflect actual work state. If you manually move things in the VK UI, run `/sync-plan` to reconcile.
- **Task titles in VK use the format `[ID] Title`.** This enables matching between the plan and VK. Don't rename tasks in VK.

---

## FAQ

### General

**Q: Do I need a VibeKanban account to use these commands?**

A: Yes. The commands create and manage tasks through VibeKanban's MCP API. You need the VibeKanban MCP server configured in your Claude Code settings. See the [README](../README.md#prerequisites) for setup instructions.

**Q: Can I use these commands with a project that wasn't started with `/generate-prd`?**

A: Yes. You can enter the workflow at any point:
- Have a PRD already? Start at `/prd-review`.
- Have a plan already? Start at `/generate-tasks`.
- Have VK tasks already? Start at `/work-next`.

The commands are designed to work independently. Earlier steps produce files that later steps consume, but you can create those files manually.

**Q: What if I don't have a PRD at all?**

A: You can write `docs/prd.md` by hand, use `/generate-prd` to create one through an interview, or jump straight to `/create-plan` and describe what you want to build. The PRD is recommended but not strictly required.

**Q: How many tasks can the plan handle?**

A: The markdown-based plan works well up to around 50-80 tasks. Beyond that, the tables become harder to parse and the file gets unwieldy. For larger projects, consider breaking them into multiple plans or using larger epics with fewer tasks each.

**Q: Can I use this with a monorepo or multiple repos?**

A: The commands assume a single project directory with `docs/prd.md` and `docs/development-plan.md`. For monorepos, you could put plans in subdirectories, but you'd need to adjust the file paths in the command files.

### Workflow

**Q: What's the difference between `/next-task` and `/work-next`?**

A: `/next-task` is read-only -- it recommends the top 3 tasks and optionally marks one as `inprogress`, but doesn't start implementation. `/work-next` does everything: recommends, confirms, implements, verifies AC, and marks done. Use `/next-task` when you want to plan without committing. Use `/work-next` when you're ready to execute.

**Q: What's the difference between `/work-task` and `/work-next`?**

A: `/work-next` picks the best available task automatically. `/work-task` lets you specify which task to work on by ID or title. Both execute the same implementation workflow once a task is selected.

**Q: Should I run `/sync-plan` after every task?**

A: Not necessarily. Running it after every 3-5 tasks or at the start/end of a work session is usually sufficient. It's most useful when you want to see a holistic progress update or detect drift.

**Q: What happens if I run `/generate-tasks` twice?**

A: It's safe. The command checks for existing VK tasks and skips ones that are already created. Only new/unlinked tasks are created.

**Q: Can I reorder epics or tasks in the plan?**

A: You can, but be careful. Task IDs (1.1, 2.3) are based on epic numbering. If you reorder epics, use `/add-epic` which handles renumbering automatically. Manual reordering risks breaking dependency references.

**Q: What does "VK is source of truth" mean in practice?**

A: When you run `/sync-plan`, the plan file is updated to match VibeKanban's task status -- not the other way around. If the plan says a task is done but VK says it's `todo`, the plan gets updated to reflect `todo`. This means you should update task status through the commands (which update VK), not by editing the plan file directly.

### Execution

**Q: Does `/work-task` actually write code?**

A: Yes. It reads the full context (PRD, plan, acceptance criteria, codebase), then implements the task by modifying your codebase. It follows existing patterns and conventions in your code. You can review changes before committing.

**Q: What if Claude's implementation is wrong?**

A: Don't mark the task as `done`. Either fix the issues in the same session, or leave it `inprogress` and come back to it. The task won't be closed until you explicitly confirm.

**Q: Can I partially complete a task?**

A: Yes. Mark it as `inreview` instead of `done`. This signals that work was done but it needs another pass. The task remains on your board.

**Q: How does fuzzy matching work in `/work-task`?**

A: If you pass a title fragment (e.g., `/work-task auth`), Claude searches both the plan and VK tasks for matches. If multiple tasks match, it presents the options and asks you to pick.

**Q: What if a task has no acceptance criteria?**

A: Claude will still implement the task using the description and PRD context, and will ask you to define ad-hoc acceptance criteria during implementation. For best results, add criteria when creating the plan.

### Plan management

**Q: Can I edit `docs/development-plan.md` by hand?**

A: Yes, but with care. The commands parse specific markdown patterns (task tables, `<!-- vk:ID -->` comments, epic headers). If you change the format, the commands may fail to parse correctly. Safe edits include updating descriptions, fixing typos, and adding notes. Avoid changing task IDs, table structure, or VK ID comments manually.

**Q: What happens when I close an epic?**

A: `/close-epic` verifies all tasks are done in VK, reviews the epic acceptance criteria with you, then updates the plan: the epic header changes to `(COMPLETE)`, the summary table shows 100%, and all AC checkboxes are checked.

**Q: Can I reopen a closed epic?**

A: There's no command for this, but you can manually change the epic header back to `(IN PROGRESS)` and uncheck acceptance criteria in the plan file. Then run `/sync-plan` to reconcile.

**Q: What's drift detection?**

A: `/sync-plan` checks for inconsistencies between the plan and VK:
- **Stale in-progress** -- tasks marked `inprogress` for a long time (may be stuck)
- **Dependency violations** -- tasks started before their dependencies were done
- **Ready to start** -- tasks whose dependencies are now satisfied
- **Scope drift** -- tasks in the plan without VK IDs (unlinked) or VK tasks not in the plan (orphaned)

### Parallel execution (experimental)

**Q: Can I run multiple tasks at the same time?**

A: Yes, experimentally. See the [Architecture doc](architecture.md) for the two-tier model:
- **Tier 1 (local):** `/work-parallel` sets up git worktrees and launches full Claude Code sessions (via Agent Teams, headless mode, or manual terminals) in each, with full file isolation and MCP access.
- **Tier 2 (remote):** `/delegate-task` uses VibeKanban workspace sessions to spawn separate agent instances.

Both are experimental and actively evolving.

**Q: How many tasks can I run in parallel?**

A: The default cap is 3 concurrent sessions. You can adjust this during the confirmation step. Each session consumes tokens and local resources, so more isn't always better.

**Q: What's the difference between Tier 1 and Tier 2 parallelism?**

A: Tier 1 uses git worktrees with full Claude Code sessions (launched via Agent Teams, headless `claude -p`, or manual terminals). Each session runs in its own worktree directory with full file isolation and MCP access for VK communication. Tier 2 spawns entirely separate agent sessions via VibeKanban -- potentially different agents like Cursor or Codex -- each in its own environment. Tier 1 is lighter and stays local. Tier 2 is fully isolated and supports different agent types.

**Q: Can I run parallel tasks that were created directly in VibeKanban (not in the plan)?**

A: Yes, but with caveats. VK-only tasks don't have plan-based IDs (like `1.3`) or dependency information. `/work-parallel` will warn you during the review step since it can't verify that VK-only tasks are safe to run concurrently. You can still include them if you know they're independent. Branch names will use a slugified version of the task title (e.g., `task/fix-login-bug`) instead of a plan ID.

**Q: Where do worktrees get created?**

A: In a sibling directory named `../<project-name>-worktrees/`. For example, if your project is at `~/Development/myproject/`, worktrees go in `~/Development/myproject-worktrees/task-2.3-add-user-api/`. This keeps them grouped and out of your main project directory. `/work-parallel` reports all paths when it creates them, and you can always run `git worktree list` to see active worktrees.

**Q: How do I clean up worktrees after merging?**

A: After a branch is merged to main, remove the worktree:

```bash
git worktree remove ../myproject-worktrees/task-2.3-add-user-api
```

Or remove all finished worktrees at once:

```bash
git worktree list                    # see what's active
git worktree prune                   # clean up stale references
rm -rf ../myproject-worktrees/       # remove the directory entirely if all done
```

**Q: How do permissions work for parallel sessions?**

A: Parallel sessions (especially headless ones) can't prompt for interactive permission approval. Before launching sessions, `/work-parallel` asks you to choose a permission mode:

| Mode | Flag | Best for |
|------|------|----------|
| **Bypass permissions** (recommended) | `--permission-mode bypassPermissions` | Most parallel workflows |
| **Skip permissions** | `--dangerously-skip-permissions` | Fast but least safe |
| **Interactive** | (default) | Manual terminals only -- you must monitor each window |
| **Pre-configured** | Uses `~/.claude/settings.json` allowedTools | If you've already configured tool allowlists |

Key notes:
- **Agent Teams** inherit the lead's permission mode. Set it on the lead before spawning teammates.
- **Headless `claude -p`** is non-interactive and **cannot respond to prompts**. You must use bypass permissions, skip permissions, or pre-configured settings.
- **Manual terminals** support any mode, but interactive requires actively monitoring all terminal windows for prompts.

**Q: How can I see what a parallel session is doing?**

A: The primary mechanism is **screen/tmux sessions**. When `/work-parallel` auto-launches sessions, it wraps each `claude -p` call inside a screen or tmux session. You can attach to observe in real time:

```bash
screen -r claude-task-2.3            # attach to observe (Ctrl-A D to detach)
screen -ls                           # list all sessions (health check)
```

During normal `claude -p` execution, the attached session is observe-only. If the agent fails, the wrapper automatically launches interactive `claude` in the same session -- you can then attach and interact directly.

Other monitoring options:

- **Log files**: Always created at `../<project>-worktrees/task-<id>.log`. Use `tail -f` to watch live output.
- **Manual terminals**: You're already watching. Use split panes to monitor all terminals simultaneously.
- **Agent Teams**: Teammates message the lead with updates, but you can't attach to see their full session output.
- **VK task status**: Always available regardless of mechanism. Run `/session-status` to check which tasks have moved to `inreview` or `done`.
- **Git activity**: Check recent commits in a worktree (`git -C ../myproject-worktrees/task-2.3-add-user-api log --oneline -5`) as a proxy for progress.

See the [Architecture doc](architecture.md#observability-and-session-monitoring) for the full observability model.

**Q: Why don't I see session history in VK for local tasks?**

A: VibeKanban's session history, diffs, and "Attempts" view are only available for **Tier 2 workspace sessions** (launched via `/delegate-task` or `/delegate-parallel`). For **Tier 1 local work** (`/work-parallel` worktrees and `/work-task` interactive sessions), VK has no direct visibility into the agent's activity.

As a workaround, the commands append a structured **Completion Log** to the task description in VK before updating the status. This log includes files changed, a summary, assumptions, and an acceptance criteria checklist. `/merge-parallel` adds a **Merge Log** subsection with merge strategy, test results, and commit count. See the recipe "Logging work results to VibeKanban" above for details.

This is a stopgap — a proper VK comment/log API would be the ideal solution. If you need full session visibility, consider using Tier 2 delegation (`/delegate-task`) instead.

**Q: Why doesn't `/merge-parallel` auto-resolve conflicts?**

A: By design. The 80% case is trivial merges that go through cleanly. For the 20% that conflict -- shared registries, config files, barrel exports -- you really want a person looking at it. Auto-resolution risks silently producing broken code that passes syntax checks but has wrong semantics (duplicate entries, wrong import order, dropped config). When `/merge-parallel` hits a conflict, it stops, reports the conflicting files, and waits. You fix it, re-run, and already-merged branches are skipped automatically.

**Q: Can parallel tasks cause merge conflicts?**

A: Yes. Each parallel session works on its own branch. When merging back to main, conflicts are possible if tasks touch related files -- especially shared registries, route tables, index/barrel files, and config files. Independent tasks that modify different files merge cleanly. Use the rebase-then-merge pattern: merge one branch, rebase the next onto the updated main, resolve conflicts, repeat.

### Human-in-the-loop and autonomy

**Q: Is this workflow fully autonomous or does it require human input?**

A: Human-in-the-loop by design. Every command has explicit human decision points: confirming which task to work on, reviewing implementations before marking done, approving parallel execution plans, choosing permission modes. There is no "run until the backlog is empty" auto-loop. Each task requires a new invocation. This is intentional -- it keeps humans engaged with progress, prevents runaway token consumption, and ensures quality through review at every step.

**Q: How does this compare to Ralph or other fully autonomous approaches?**

A: Tools like [Ralph](https://github.com/frankbria/ralph-claude-code) take a different approach: continuous autonomous execution loops where the agent iterates on the project with minimal human intervention, using guardrails like rate limiting and circuit breakers to stay safe.

This workflow prioritizes **structured planning and human judgment**: PRD → plan → tasks with dependencies → human-confirmed execution → AC verification → human review before merge. Ralph prioritizes **speed of iteration**: read a prompt file → loop until done → use automated guardrails to detect stuck states.

Neither is universally better:
- Use this workflow when you need structured decomposition, dependency-aware parallelism, quality gates, multi-agent coordination, or persistent tracking across sessions.
- Use an autonomous loop when scope is well-defined, tasks are straightforward, and speed matters more than review.
- They can complement each other: use this workflow for planning (PRD → plan → tasks), then hand well-scoped tasks to an autonomous loop for execution.

See the [Architecture doc](architecture.md#human-in-the-loop-philosophy) for a detailed comparison table.

**Q: Can I make this workflow more autonomous?**

A: Partially. For parallel sessions, you can choose `--dangerously-skip-permissions` or `--permission-mode bypassPermissions` to let agents run without permission prompts. Headless `claude -p` sessions run without interactive input. But the planning pipeline (`/generate-prd`, `/prd-review`, `/create-plan`) is inherently interactive -- it needs your domain knowledge and judgment. The execution commands (`/work-next`, `/work-task`) always confirm before starting work. This is by design: the human-in-the-loop steps are where quality happens.

### Agent Teams and multi-agent

**Q: How does this compare to Claude Code Agent Teams?**

A: They're complementary. This workflow provides the planning layer (PRD, task decomposition, dependencies, acceptance criteria, progress tracking). Agent Teams provides runtime coordination (inter-agent messaging, task claiming with locking, split-pane visibility). Use this workflow to figure out *what* to parallelize; use Agent Teams to coordinate *how* agents execute in parallel. See the [Architecture doc](architecture.md#relationship-to-claude-code-agent-teams) for a detailed comparison.

**Q: Can I use Agent Teams with this workflow?**

A: Yes, and it's a powerful combination. Use `/create-plan` and `/generate-tasks` to build the plan and populate VK. Then spawn an Agent Team where teammates each pick up a VK task, use the MCP API to update status, and coordinate with each other. After they finish, run `/sync-plan` to reconcile the plan.

**Q: Does this only work with Claude Code?**

A: The slash commands are Claude Code markdown prompts, so they run in Claude Code. But the underlying infrastructure is agent-agnostic. The VibeKanban MCP API, the development plan file, and the MCP tool calls all work with any MCP-compatible agent. A Cursor, Codex, or Gemini agent can read the same plan, pick up VK tasks, and update status through the same API. Tier 2 (`/delegate-task`) explicitly supports spawning different agent types via VK workspace sessions.

**Q: Does Agent Teams replace the need for this workflow?**

A: No. Agent Teams has no planning pipeline, no PRD generation, no structured task decomposition with dependencies, no acceptance criteria verification, and no persistent tracking across sessions (team state is lost on cleanup). This workflow provides the structured decomposition that makes parallel execution effective -- without it, you're parallelizing without knowing what's safe to parallelize or what "done" means.

---

## Troubleshooting

### Commands not appearing

**Problem:** Typing `/generate-prd` or other commands does nothing.

**Fix:**
1. Verify commands are installed: `ls ~/.claude/commands/`
2. Re-run the installer: `./install.sh`
3. Restart your Claude Code session
4. Check file permissions: `ls -la ~/.claude/commands/*.md`

### "VibeKanban project not found"

**Problem:** Commands that interact with VK can't find the project.

**Fix:**
1. Verify MCP server is configured: type `/mcp` in Claude Code
2. Check that the VibeKanban project exists and you have access
3. Make sure the project name/ID in the plan matches what's in VK
4. Try `list_projects` manually to see available projects

### Tasks not syncing

**Problem:** `/sync-plan` doesn't update or shows everything as unchanged.

**Fix:**
1. Check that plan tasks have VK IDs: look for `<!-- vk:UUID -->` in the task table
2. If VK IDs are missing, run `/generate-tasks` first
3. Verify the VK task IDs are valid (not placeholder text)
4. Check that the VibeKanban project has the tasks

### "Bash command permission check failed"

**Problem:** A command triggers a bash permission error.

**Fix:** This was a known issue in earlier versions where commands used inline bash execution. Update to the latest commands:

```bash
cd /path/to/claude-vibekanban
git pull
./install.sh --force
```

### Plan file parse errors

**Problem:** Commands fail to parse the development plan.

**Fix:**
1. Check that the task table has exactly 7 columns: ID, Title, Description, Priority, Complexity, Depends On, Status
2. Verify epic headers follow the format: `## Epic N: Name (STATUS)`
3. Check that `<!-- vk:ID -->` comments are in the Status column, not elsewhere
4. Look for broken markdown table formatting (misaligned pipes, missing cells)

### Dependency warnings on every task

**Problem:** `/work-next` warns about unmet dependencies for all recommended tasks.

**Fix:**
1. Run `/sync-plan` to update VK status -- dependencies may already be done
2. Check that foundational tasks (Epic 1) are actually marked `done` in VK
3. Verify dependency references use correct task IDs (e.g., `1.1`, not `Task 1.1`)

### Task created in VK but not linked in plan

**Problem:** Tasks exist in VK but the plan shows `<!-- vk: -->` (empty).

**Fix:** Run `/generate-tasks` again. It will match existing VK tasks to plan tasks and fill in the missing IDs. It won't create duplicates.

### `/work-task` can't find a task by title

**Problem:** Fuzzy matching doesn't find the task you mean.

**Fix:**
1. Use the plan task ID instead: `/work-task 2.3`
2. Use a more specific title fragment
3. Run `/work-task` with no argument to browse and select

### Multiple VK projects -- wrong one selected

**Problem:** Commands operate on the wrong VibeKanban project.

**Fix:**
1. Check the `VibeKanban Project ID` in the plan header metadata
2. If it's wrong, update it manually
3. If you have multiple projects, the commands will ask you to select one when ambiguous

### Worktree creation fails

**Problem:** `git worktree add` fails with "branch already exists" or "is already checked out."

**Fix:**
1. Check if the branch already exists: `git branch --list task/2.3-*`
2. If the branch exists but the worktree doesn't, delete the stale branch: `git branch -d task/2.3-add-user-api`
3. If the worktree exists, ask whether to reuse it or create fresh: `git worktree list`
4. Clean up stale worktree references: `git worktree prune`

### Headless session not starting or hangs

**Problem:** `claude -p` doesn't produce output or seems stuck.

**Fix:**
1. Check if the process is running: `ps aux | grep claude`
2. Ensure you used a permission flag -- headless mode **cannot respond to prompts**. Use `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`
3. Verify MCP server is accessible from the worktree directory
4. Check the log file if you redirected output: `tail -20 ../myproject-worktrees/task-2.3.log`

### Parallel session produces no commits

**Problem:** `/session-status` shows a task is `inprogress` but the worktree branch has no new commits.

**Fix:**
1. The session may still be analyzing or generating code -- give it more time
2. Check the log file or terminal for errors
3. If the session is stuck on a permission prompt (headless without proper flags), it will never progress. Kill it and relaunch with the right permission flag
4. If the session failed silently, check if the task is still `inprogress` in VK and relaunch manually

### Merge conflicts after parallel work

**Problem:** Rebasing a parallel branch onto main produces conflicts.

**Fix:**
1. This is expected, especially in shared files (registries, configs, index files)
2. Resolve conflicts manually: `git rebase main`, fix conflicts, `git rebase --continue`
3. Merge branches in order from least-conflicting to most-conflicting
4. For severe conflicts, consider merging the branch manually and discarding the worktree

### `/delegate-task` or `/delegate-parallel` fails

**Problem:** `start_workspace_session` returns an error.

**Fix:**
1. Verify the VK project has repos configured: check with `list_repos`
2. Ensure the task ID is valid and the task exists in VK
3. Check that the executor type is supported (CLAUDE_CODE, CURSOR_AGENT, CODEX, GEMINI, COPILOT, DROID)
4. Verify the base branch exists and is accessible

### VK workspace session stuck on "loading history"

**Problem:** After delegating a task, the VK UI shows "loading history" indefinitely. The task stays in `todo`. Server logs show:

```
WARN services::services::worktree_manager: git worktree add failed;
  attempting metadata cleanup and retry: Invalid repository:
  git command failed: fatal: invalid reference: vk/<branch-name>
```

**Cause:** VK's server-side worktree manager failed to create the git worktree and workspace branch. This is a known class of issue in VK's worktree management (see [VK #306](https://github.com/BloopAI/vibe-kanban/issues/306)).

**Fix:**
1. Run `git worktree prune` in the repository that VK is managing to clean up stale worktree metadata
2. Update VK to the latest version -- worktree bugs have been fixed in past releases
3. Retry the delegation

**Workaround -- fall back to Tier 1:** If the issue persists, bypass VK's worktree manager entirely by using local execution instead:

```
/work-parallel 2.3          # single task, creates local worktree + headless session
```

Or manually:

```bash
git worktree add ../myproject-worktrees/task-2.3-add-user-api -b task/2.3-add-user-api
cd ../myproject-worktrees/task-2.3-add-user-api
claude                       # then use /work-task inside the session
```

Tier 1 creates worktrees locally with plain `git worktree add` and doesn't depend on VK's worktree manager at all. The agent still updates VK task status via MCP, and completion logs are appended to the task description. You lose VK's session history and diff view, but the task gets done. See the [Architecture doc](architecture.md#two-tier-parallel-execution-model) for the full Tier 1 vs Tier 2 comparison.

### `/merge-parallel` stops at conflicts

**Problem:** `/merge-parallel` stops mid-way through merging branches due to a conflict.

**Fix:** This is by design. Merge conflicts require human judgment to resolve correctly.

1. Look at the conflicting files listed in the output
2. Resolve the conflicts manually (`git add <resolved-files> && git commit` for merge, or `git add <resolved-files> && git rebase --continue` for rebase)
3. Re-run `/merge-parallel` -- it will detect already-merged branches and skip them, continuing with the remaining branches

**Tip:** If you expect many conflicts, consider merging the simplest/most isolated branches first (the default order) to minimize cascading conflicts.

### Stale worktrees after sessions complete

**Problem:** Worktrees remain after tasks are done, cluttering the filesystem.

**Fix:**
```bash
git worktree list                              # see all worktrees
git worktree remove ../myproject-worktrees/task-2.3-add-user-api  # remove specific
git worktree prune                             # clean stale references
rm -rf ../myproject-worktrees/                 # remove all if everything is merged
```

Run `/session-status` to see which worktrees correspond to completed tasks and can safely be removed.

---

## Command Quick Reference

| Command | Input | Modifies Plan | Modifies VK | Modifies Code |
|---------|-------|:---:|:---:|:---:|
| `/generate-prd` | Project idea (optional) | No (creates PRD) | No | No |
| `/prd-review` | None (reads PRD) | No | No | No |
| `/create-plan` | None (reads PRD) | Yes (creates plan) | No | No |
| `/generate-tasks` | None (reads plan) | Yes (adds VK IDs) | Yes (creates tasks) | No |
| `/sync-plan` | None | Yes (updates status) | No | No |
| `/plan-status` | None | No | No | No |
| `/next-task` | None | No | Optionally (mark inprogress) | No |
| `/work-task` | Task ID or title | No | Yes (status updates) | Yes |
| `/work-next` | None | No | Yes (status updates) | Yes |
| `/add-epic` | Epic details | Yes (adds epic) | No | No |
| `/close-epic` | Epic name/number | Yes (marks complete) | No | No |
| `/workflow` | None | No | No | No |

### Experimental commands

| Command | Input | Modifies Plan | Modifies VK | Modifies Code | Creates Worktrees |
|---------|-------|:---:|:---:|:---:|:---:|
| `/work-parallel` | Task IDs (optional) | No | Yes (marks inprogress) | Yes (in worktrees) | Yes |
| `/merge-parallel` | None | No | Yes (marks done) | No | No (removes) |
| `/delegate-task` | Task ID or title | No | Yes (starts session) | Yes (remote) | No |
| `/delegate-parallel` | Task IDs or titles | No | Yes (starts sessions) | Yes (remote) | No |
| `/session-status` | None | No | No | No | No |
