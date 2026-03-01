---
description: Autonomous work loop - parallel execution, monitoring, merging, and testing until all tasks pass
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task, mcp__vibe_kanban__list_repos
version: 0.1.0-preview
date: 2026-03-01
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Autonomous Parallel Work Loop (Experimental)

> **This command is experimental.** It orchestrates a fully autonomous loop of parallel task execution, monitoring, merging, testing, and iteration. Designed for maximum autonomy with minimal human intervention.

## Context

You are running an autonomous work loop that repeatedly:
1. Identifies and launches parallel tasks
2. Monitors sessions for completion or failure
3. Merges completed branches
4. Runs the test suite
5. Fixes failures or launches the next batch
6. Repeats until all tasks are done and tests pass

This command composes the existing `/work-parallel`, `/session-status`, `/merge-parallel`, and `/sync-plan` workflows into a single autonomous loop. It is designed to run with `--permission-mode bypassPermissions` so no human input is needed during execution.

**Important:** The user should launch their Claude Code session with `--permission-mode bypassPermissions` or `--dangerously-skip-permissions` for this command to work without interruption.

## Instructions

### 0. Pre-Flight Check

Before entering the loop, verify prerequisites:

1. **Development plan exists**: Read `docs/development-plan.md`. If missing, stop and tell the user to run `/create-plan` first.
2. **VK project exists**: Use `list_projects` to find the project. If none, stop and tell the user to run `/generate-tasks` first.
3. **Clean git state**: Run `git status --porcelain`. If dirty, stop and tell the user to commit or stash first.
4. **Test command**: Ask the user for their test command (e.g., `npm test`, `pytest`, `make test`). This is **required** — the loop uses test results as the exit condition.
5. **Max parallel sessions**: Ask the user for the max parallel session count (default: 3).
6. **Session manager available**: Check for `screen` or `tmux` via `which screen` / `which tmux`. Warn if neither is found (background-only mode has no recovery).

Record these settings — they persist for the entire loop.

```
## Work Loop Configuration

| Setting | Value |
|---------|-------|
| Test command | `npm test` |
| Max parallel | 3 |
| Session manager | screen |
| Permission mode | bypassPermissions |
| Started at | 2026-03-01 14:30:00 |
```

**After configuration, confirm with the user one final time before entering the autonomous loop.** This is the last human checkpoint.

### 1. PHASE: Assess Backlog

At the start of each loop iteration:

1. Use `list_projects` to find the project
2. Use `list_tasks` to get all tasks and current status
3. Read `docs/development-plan.md` for dependency data
4. Identify **available tasks**: status `todo` in VK, all dependencies `done`
5. Check for mutual dependencies — only select tasks that are independent of each other
6. Select up to the configured max parallel tasks, ranked by:
   - Priority (urgent > high > medium > low)
   - Complexity (S > M > L — prefer smaller for faster iteration)
   - Epic order (earlier epics first)
   - Unblocking potential (tasks that unblock others rank higher)

**Exit condition check:** If NO tasks are available (all are `done`, `inprogress`, or blocked), skip to Phase 5 (Test & Verify) to run the final test suite.

**If only 1 task is available**, still proceed — single-task "parallel" is fine. The loop handles it.

### 2. PHASE: Launch Parallel Sessions

For each selected task, follow the `/work-parallel` launch procedure:

1. **Create worktrees:**
   ```bash
   mkdir -p ../<project-name>-worktrees
   git worktree add ../<project-name>-worktrees/<branch-name> -b <branch-name>
   ```

   Branch naming: `task/<plan-id>-<slugified-title>` (e.g., `task/2.3-add-user-api`)

2. **Mark tasks as `inprogress`** in VK via `update_task`

3. **Build the prompt** for each session with full context:
   - Task description and acceptance criteria from the plan
   - Relevant PRD sections
   - Instruction to append a Completion Log to the VK task description when done
   - Instruction to mark the task as `inreview` when finished
   - Instruction to commit all work before exiting

4. **Launch sessions** using the detected session manager:

   **Screen (preferred):**
   ```bash
   screen -dmS claude-task-<id> -L -Logfile ../<project>-worktrees/task-<id>.log bash -c '
     cd ../<project>-worktrees/<branch-name>
     claude -p "<prompt>" --permission-mode bypassPermissions 2>&1
     EXIT_CODE=$?
     if [ $EXIT_CODE -ne 0 ]; then
       echo ""
       echo "SESSION_STATUS: FAILED (exit code $EXIT_CODE)"
     else
       echo ""
       echo "SESSION_STATUS: COMPLETED"
     fi
   '
   ```

   **Note:** Unlike `/work-parallel`, do NOT launch interactive recovery on failure. The loop orchestrator handles stuck/failed sessions itself.

   **Tmux (fallback):**
   ```bash
   tmux new-session -d -s claude-task-<id> bash -c '
     cd ../<project>-worktrees/<branch-name>
     claude -p "<prompt>" --permission-mode bypassPermissions 2>&1
     EXIT_CODE=$?
     if [ $EXIT_CODE -ne 0 ]; then
       echo ""
       echo "SESSION_STATUS: FAILED (exit code $EXIT_CODE)"
     else
       echo ""
       echo "SESSION_STATUS: COMPLETED"
     fi
   '
   tmux pipe-pane -t claude-task-<id> "cat >> ../<project>-worktrees/task-<id>.log"
   ```

   **Background (no recovery):**
   ```bash
   cd ../<project>-worktrees/<branch-name> && (claude -p "<prompt>" --permission-mode bypassPermissions 2>&1; EXIT_CODE=$?; if [ $EXIT_CODE -ne 0 ]; then echo "SESSION_STATUS: FAILED (exit code $EXIT_CODE)"; else echo "SESSION_STATUS: COMPLETED"; fi) > ../<project>-worktrees/task-<id>.log 2>&1 &
   ```

5. **Report launched sessions:**
   ```
   ## Loop Iteration N - Sessions Launched

   | Task | Session | Branch | Log File |
   |------|---------|--------|----------|
   | 2.3 - Add user API | claude-task-2.3 | task/2.3-add-user-api | task-2.3.log |
   ```

### 3. PHASE: Monitor Sessions

Enter a monitoring loop that checks session status every **2 minutes**:

```bash
sleep 120
```

After each sleep, perform these checks for every active session:

#### 3a. Check Session Alive Status

```bash
screen -ls 2>/dev/null | grep "claude-task-"
# or
tmux list-sessions 2>/dev/null | grep "claude-task-"
```

#### 3b. Check VK Task Status

Use `list_tasks` to refresh all task statuses. For each launched task:

| VK Status | Session Alive | Action |
|-----------|---------------|--------|
| `inreview` or `done` | Any | **Session complete** — mark for merge |
| `inprogress` | Alive | Check log freshness (3c) |
| `inprogress` | Dead | Check log markers (3d) |

#### 3c. Check Log Freshness (if session alive + inprogress)

```bash
# Check if log was modified in the last 10 minutes
find ../<project>-worktrees/task-<id>.log -mmin -10 2>/dev/null
```

Also check for git activity in the worktree:

```bash
git -C ../<project>-worktrees/<branch-name> log --oneline -1 --format="%cr" 2>/dev/null
```

- **Log fresh OR recent git commits**: Session is active. Continue monitoring.
- **Log stale (10+ min) AND no recent commits**: Session may be stuck. Proceed to intervention (3e).

#### 3d. Check Log Markers (if session dead + inprogress)

```bash
tail -10 ../<project>-worktrees/task-<id>.log 2>/dev/null | grep "SESSION_STATUS:"
```

- `SESSION_STATUS: COMPLETED` → Session finished but didn't update VK. Mark for merge, update VK to `inreview`.
- `SESSION_STATUS: FAILED` → Session failed. Proceed to intervention (3e).
- No marker → Unknown state. Check for git commits. If commits exist, mark for merge. If no commits, proceed to intervention (3e).

#### 3e. Intervene on Stuck/Failed Sessions

When a session is stuck or failed:

1. **Kill the dead/stuck session:**
   ```bash
   screen -X -S claude-task-<id> quit 2>/dev/null
   # or
   tmux kill-session -t claude-task-<id> 2>/dev/null
   ```

2. **Check if the session made partial progress:**
   ```bash
   git -C ../<project>-worktrees/<branch-name> log --oneline -5 2>/dev/null
   ```

3. **If commits exist** (partial progress): Re-launch a new session in the same worktree with a modified prompt:
   ```
   "Continue implementing task [title]. The previous session made partial progress.
   Check what has been done (review the git log and current code state),
   complete any remaining work, and fulfill all acceptance criteria.
   [original AC and context]
   When done, append a Completion Log to the VK task description and mark as inreview."
   ```

4. **If no commits** (no progress): Re-launch with the original prompt. This is the first retry.

5. **Track retry count.** If a task has been retried **2 times** and still fails:
   - Mark the task as `inreview` in VK with a note: "Auto-loop: task failed after 2 retries. Needs manual investigation."
   - Skip it for the remainder of this loop run
   - Continue with other tasks

6. **Report intervention:**
   ```
   ## Intervention: Task 2.3

   - Session: claude-task-2.3 (DEAD, no SESSION_STATUS marker)
   - Git commits: 3 (partial progress)
   - Action: Re-launched with continuation prompt
   - Retry: 1 of 2
   ```

#### 3f. Monitor Loop Exit

Exit the monitoring phase when ALL launched sessions are in one of these states:
- VK status is `inreview` or `done`
- Marked as "skip" after max retries
- Session dead with `SESSION_STATUS: COMPLETED`

Print a summary before proceeding:

```
## Monitoring Complete

| Task | Final Status | Commits | Retries |
|------|-------------|---------|---------|
| 2.3 - Add user API | inreview | 8 | 0 |
| 3.1 - Setup database | inreview | 5 | 1 |
| 4.2 - Add logging | skipped (2 retries) | 0 | 2 |
```

### 4. PHASE: Merge & Clean Up

Follow the `/merge-parallel` procedure, but **automated** (no user confirmation needed):

1. **Detect default branch:**
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
   ```
   Fall back to checking for `main` or `master`.

2. **Identify merge-ready branches** by cross-referencing VK status:
   - `done` or `inreview` → merge
   - `inprogress` → skip (shouldn't happen if monitoring phase completed)
   - Already merged (`git branch --merged`) → skip

3. **Sort by fewest commits** (simplest first to minimize cascading conflicts)

4. **Execute merges sequentially:**
   ```bash
   git checkout <default-branch>
   git pull --ff-only
   git merge <branch> --no-edit
   ```

5. **On merge conflicts — attempt auto-resolve:**

   When a merge conflict occurs:

   a. First, check the nature of the conflicts:
   ```bash
   git diff --name-only --diff-filter=U
   ```

   b. Attempt auto-resolution strategies in order:
   - **Strategy 1: Theirs for non-overlapping changes.** If the conflict is in files that only the feature branch modified (not modified on the default branch since the branch point), accept theirs:
     ```bash
     git checkout --theirs <conflicting-file>
     git add <conflicting-file>
     ```
   - **Strategy 2: Manual merge via Claude.** Read both versions of the conflicting file, understand the intent of both changes, and write a merged version that preserves both sets of changes. Use the Edit tool to fix the conflict markers, then:
     ```bash
     git add <resolved-file>
     ```
   - **Strategy 3: If resolution is unclear** (e.g., both branches modified the same lines with incompatible logic), abort the merge and skip this branch:
     ```bash
     git merge --abort
     ```
     Mark the task with a note: "Auto-loop: merge conflict could not be auto-resolved. Needs manual merge."
     Move on to the next branch.

   c. After resolving all conflicts for a merge, commit:
   ```bash
   git commit --no-edit
   ```

6. **Update VK task descriptions** — append Merge Log to each merged task (following `/merge-parallel` format)

7. **Update VK status** — set `inreview` tasks to `done`

8. **Clean up:**
   ```bash
   # Remove worktrees
   git worktree remove ../<project>-worktrees/<branch-name> --force 2>/dev/null

   # Delete merged branches
   git branch -d <branch> 2>/dev/null

   # Kill any lingering sessions
   screen -X -S claude-task-<id> quit 2>/dev/null
   tmux kill-session -t claude-task-<id> 2>/dev/null

   # Prune stale worktree references
   git worktree prune
   ```

   Remove the worktrees directory if empty:
   ```bash
   rmdir ../<project>-worktrees 2>/dev/null
   ```

9. **Report merge results:**
   ```
   ## Merge Results (Iteration N)

   | Task | Strategy | Conflicts | Test After Merge | Status |
   |------|----------|-----------|------------------|--------|
   | 2.3 - Add user API | merge | None | - | Merged |
   | 3.1 - Setup database | merge | 1 file (auto-resolved) | - | Merged |
   | 4.2 - Add logging | - | - | - | Skipped (failed) |
   ```

### 5. PHASE: Test & Verify

Run the test suite on the default branch after all merges:

```bash
git checkout <default-branch>
<test-command>
```

**If tests pass (exit code 0):**

Check if there are more tasks remaining in the backlog:
- If YES → continue to Phase 6 (Sync & Iterate)
- If NO (all tasks `done`) → proceed to Phase 7 (Finalize)

**If tests fail (non-zero exit code):**

1. **Capture the test output** and analyze the failures
2. **Categorize failures:**

   | Failure Type | Action |
   |-------------|--------|
   | Test references code from a merged branch that has a bug | Create a fix task in VK, add to next iteration |
   | Integration conflict between merged branches | Attempt to fix inline on the default branch |
   | Flaky/environmental test | Re-run once. If still fails, flag for manual review |
   | Compilation/import error | Attempt to fix inline (likely a missing merge artifact) |

3. **For inline fixes**: Fix the issue directly on the default branch using your tools (Read, Edit, Write). Commit the fix:
   ```bash
   git add <fixed-files>
   git commit -m "fix: resolve test failures after parallel merge

   [describe what was fixed]

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
   ```

4. **Re-run tests** after inline fixes. If they pass, continue. If they still fail after **2 fix attempts**, create VK tasks for the remaining failures and note them for manual review.

5. **For new fix tasks**: Use `create_task` (if available) or note them for the next iteration. These become highest-priority tasks in the next loop.

### 6. PHASE: Sync & Iterate

1. **Sync the development plan:**
   Follow the `/sync-plan` procedure:
   - Read `docs/development-plan.md`
   - Fetch VK task statuses
   - Update epic progress percentages
   - Update epic status headers
   - Update changelog
   - Write the updated plan

2. **Commit the sync:**
   ```bash
   git add docs/development-plan.md
   git commit -m "chore: sync development plan after loop iteration N

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
   ```

3. **Check loop continuation:**
   - Use `list_tasks` to check remaining backlog
   - If there are `todo` tasks with satisfied dependencies → **go back to Phase 1**
   - If all remaining tasks are blocked → report what's blocking and **go back to Phase 1** (blocked tasks may have been unblocked by this iteration's completed work)
   - If all tasks are `done` and tests pass → proceed to Phase 7

4. **Print iteration summary:**
   ```
   ## Iteration N Complete

   | Metric | Value |
   |--------|-------|
   | Tasks completed this iteration | 3 |
   | Tasks failed/skipped | 1 |
   | Merge conflicts auto-resolved | 1 |
   | Test fixes applied | 0 |
   | Total tasks done | 8/15 |
   | Remaining available | 4 |
   | Blocked | 3 |

   Proceeding to iteration N+1...
   ```

### 7. PHASE: Finalize

When all tasks are `done` and tests pass:

1. **Final sync:**
   Follow `/sync-plan` one last time to ensure the plan is fully up to date.

2. **Final commit:**
   ```bash
   git add -A
   git commit -m "chore: complete autonomous work loop - all tasks done, tests passing

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
   ```

3. **Print final report:**
   ```
   ## Autonomous Work Loop Complete

   | Metric | Value |
   |--------|-------|
   | Total iterations | 4 |
   | Total tasks completed | 15 |
   | Total tasks failed (need manual review) | 1 |
   | Total merge conflicts auto-resolved | 3 |
   | Total test fix commits | 2 |
   | Final test suite | PASSING |
   | Started at | 2026-03-01 14:30:00 |
   | Finished at | 2026-03-01 16:45:00 |

   ### Tasks Needing Manual Review
   - 4.2 - Add logging: Failed after 2 retries (no commits produced)

   ### All Merged Branches
   - task/1.1-project-setup (3 commits)
   - task/1.2-configure-linting (2 commits)
   - task/2.3-add-user-api (8 commits)
   - ...

   ### Next Steps
   - Review the changes: `git log --oneline -20`
   - Check failed tasks manually
   - Push when ready: `git push`
   - Run `/plan-status` for the final progress view
   ```

4. **Do NOT push to remote.** Leave that decision to the user.

### 8. Handle Edge Cases

- **No tasks available at start**: Report that all tasks are done or blocked. Run the test suite anyway and finalize if passing.
- **All sessions fail in an iteration**: After retries are exhausted, proceed to merge whatever succeeded. If nothing to merge, skip to test phase. If tests pass with prior work, sync and check for new available tasks.
- **Worktree already exists**: If a worktree/branch already exists for a task, check if it has commits. If yes, reuse it (continue where left off). If no, remove and recreate it.
- **Git worktree add fails**: Try with a different branch name (append `-retry`). If still fails, skip the task this iteration.
- **Loop runs for more than 10 iterations without convergence**: Stop and report. Something is likely wrong (circular dependencies, perpetually failing tests, etc.).
- **Disk space**: Not monitored, but if git operations fail unexpectedly, suggest checking disk space.
- **Concurrent users**: This loop assumes it is the only agent modifying the repository. Running multiple loops simultaneously on the same repo will cause conflicts.
- **No test command works**: If the test command fails to execute (not "tests fail" but "command not found"), stop the loop and ask the user to fix the test setup.

### 9. Safety Guardrails

- **Max iterations**: Hard cap at 10 iterations. If the loop hasn't converged after 10 iterations, stop and report.
- **Max retries per task**: 2 retries. After that, skip and flag for manual review.
- **Max test fix attempts**: 2 inline fix attempts per test phase. After that, create VK tasks for remaining failures.
- **No force pushes**: Never use `git push --force` or `git reset --hard`.
- **No branch deletion of unmerged branches**: Only delete branches that are confirmed merged via `git branch --merged`.
- **Conflict resolution safety**: If auto-resolution produces a file that doesn't compile/parse, revert the resolution and skip the branch.
- **Always commit before cleanup**: Ensure all work is committed before removing worktrees.

### 10. Monitoring Dashboard

Tell the user they can run the monitoring dashboard in a separate terminal for live status:

```
## Live Monitoring

Run this in a separate terminal for real-time status:

  ./scripts/monitor-sessions.sh

Or use these manual commands:
  screen -ls                    # Check active sessions
  tail -f ../<project>-worktrees/task-*.log  # Watch all logs
  screen -r claude-task-<id>    # Attach to a session (Ctrl-A D to detach)
```
