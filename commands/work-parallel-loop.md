---
description: Autonomous work loop - parallel execution, monitoring, merging, and testing until all tasks pass
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task, mcp__vibe_kanban__list_repos, mcp__vibe_kanban__list_issues, mcp__vibe_kanban__list_tags, mcp__vibe_kanban__list_issue_tags
version: 0.1.0-preview
date: 2026-03-01
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Autonomous Parallel Work Loop (Experimental)

> **This command is experimental.** It orchestrates a fully autonomous loop of parallel task execution, monitoring, merging, testing, and iteration. Designed for maximum autonomy with minimal human intervention.

## Prerequisites: Permission Mode

This command orchestrates many bash operations (git worktree management, screen/tmux sessions, `claude -p` child processes, branch merging, cleanup) that will each trigger permission prompts under the default mode. **You must start the main Claude Code session with elevated permissions:**

```bash
# Recommended — bypasses all permission prompts in the orchestrator session
claude --permission-mode bypassPermissions

# Alternative
claude --dangerously-skip-permissions
```

Without this, you will be prompted dozens of times for git, screen/tmux, and process management commands throughout the loop. The spawned child sessions already use `--permission-mode bypassPermissions` internally, but the main orchestrator session needs it too.

## Context

You are running an autonomous work loop that repeatedly:
1. Identifies and launches parallel tasks
2. Monitors sessions for completion or failure
3. Merges completed branches
4. Runs the test suite
5. Fixes failures or launches the next batch
6. Repeats until all tasks are done and tests pass

This command composes the existing `/work-parallel`, `/session-status`, `/merge-parallel`, and `/sync-plan` workflows into a single autonomous loop.

## Instructions

### 0. Pre-Flight Check

Before entering the loop, verify prerequisites:

1. **Development plan exists**: Read `docs/development-plan.md`. If missing, stop and tell the user to run `/create-plan` first.
2. **VK project exists**: Use `list_projects` to find the project. If none, stop and tell the user to run `/generate-tasks` first.
3. **Clean git state**: Run `git status --porcelain`. If dirty, stop and tell the user to commit or stash first.
4. **Goal scope**: Ask the user what scope the loop should target. Present these options:

   | Goal Type | User Input Example | What It Means |
   |-----------|-------------------|---------------|
   | All tasks (default) | *(enter)* | Current behavior — finish everything |
   | Epic | `"Epic 3"`, `"3"`, `"TRK"` | Complete all tasks in a specific epic |
   | Tag | `"mvp"`, `"sprint-1"` | Complete all VK issues with a specific tag |
   | Specific tasks | `"2.1, 2.3, 3.1"` | Complete a listed set of plan task IDs |
   | Custom predicate | `"./scripts/check-ready.sh"` | Loop exits when bash command returns 0 |

   After goal selection, compute **dependency expansion** for epic/tag/specific goals: if any in-scope task depends on an out-of-scope task that isn't `done`, pull that prerequisite into the effective working set. Report the expansion to the user:

   ```
   ## Goal Scope: Epic 3 [TRK]

   In-scope tasks: 2.1, 3.1, 3.2, 3.3, 3.4
   Dependency expansion: +1.2 (prerequisite of 3.1), +2.3 (prerequisite of 3.2)
   Effective working set: 7 tasks (5 in-scope + 2 prerequisites)
   ```

   If the expansion more than doubles the original scope (>2x), warn the user and suggest "All tasks" instead. Confirm the effective working set before proceeding.

   For **tag** goals, use `list_tags` to validate the tag exists and `list_issues` with `tag_name` to find matching issues. If no issues match, report this and ask for a different tag.

   For **custom predicate** goals, verify the command exists and is executable. If not found, stop and tell the user.

5. **Test command**: Ask the user for their test command (e.g., `npm test`, `pytest`, `make test`). This is **required** — the loop uses test results as the exit condition.
6. **Max parallel sessions**: Ask the user for the max parallel session count (default: 3).
7. **Session manager available**: Check for `screen` or `tmux` via `which screen` / `which tmux`. Warn if neither is found (background-only mode has no recovery).
8. **Estimate iterations needed**: Before starting, analyze the backlog to estimate how many loop iterations will be required:
   - Use `list_issues` (or `list_tasks`) to count remaining `todo` tasks **within the effective scope** (all tasks for "All tasks" goal; only in-scope + expanded prerequisites for scoped goals)
   - Read `docs/development-plan.md` to understand the dependency graph
   - Calculate the estimated iterations using: `ceil(in_scope_remaining_tasks / max_parallel_sessions)` — this is a lower bound since dependencies, retries, and test fixes add iterations
   - Add a buffer of +2 iterations (for merge conflicts, test fixes, and retries)
   - Present the estimate to the user and let them choose the iteration cap:

   ```
   ## Iteration Estimate

   | Metric | Value |
   |--------|-------|
   | In-scope remaining tasks (todo) | 7 |
   | Prerequisites (expanded) | 2 |
   | Max parallel sessions | 3 |
   | Estimated iterations (minimum) | 3 |
   | Recommended cap (with buffer) | 5 |

   The loop will stop automatically when all in-scope tasks are done and tests pass,
   or when it hits the iteration cap — whichever comes first.
   ```

   Ask the user: **"Recommended iteration cap is N. Use this, or specify a different limit?"** (Default: the recommended cap. Minimum: 1. Hard maximum: 50 — to prevent truly runaway loops.)

Record these settings — they persist for the entire loop.

```
## Work Loop Configuration

| Setting | Value |
|---------|-------|
| Goal | Epic 3 [TRK] — 5 in-scope + 2 prerequisites |
| Test command | `npm test` |
| Max parallel | 3 |
| Session manager | screen |
| Iteration cap | 5 (estimated 3 + 2 buffer) |
| Permission mode | bypassPermissions |
| Started at | 2026-03-01 14:30:00 |
```

**After configuration, confirm with the user one final time before entering the autonomous loop.** This is the last human checkpoint.

### Goal Predicate Reference

Two predicates are used throughout the loop phases to implement goal-scoped behavior:

#### `in_scope(task)` — Is this task part of the goal?

| Goal Type | Rule |
|-----------|------|
| All tasks | Always true |
| Epic N | Task ID starts with `N.` (e.g., task `3.2` is in scope for Epic 3) |
| Tag "X" | Task's VK issue has tag "X" — check via `list_issues` with `tag_name` filter |
| Specific IDs | Task ID is in the user's provided list |
| Custom predicate | Always true (custom predicate controls exit, not task selection) |

**Note:** The effective working set includes both in-scope tasks AND their expanded prerequisites. Tasks added via dependency expansion are worked on but are not part of the original scope for finalization purposes.

#### `goal_met()` — Should the loop finalize?

| Goal Type | Condition |
|-----------|-----------|
| All tasks | All tasks are `done` AND tests pass |
| Epic N | All originally-scoped Epic N tasks are `done` AND tests pass |
| Tag "X" | All originally-scoped tagged tasks are `done` AND tests pass |
| Specific IDs | All user-specified task IDs are `done` AND tests pass |
| Custom predicate | Bash command exits 0 AND tests pass |

**Key design decision:** `goal_met()` checks the **original scope**, not the expanded effective scope. Prerequisite tasks that were pulled in via dependency expansion do not need to be `done` for the goal to be met — only the originally-scoped tasks matter. However, in practice, prerequisites will typically be completed first since they block in-scope tasks.

**Custom predicate behavior:** Unlike other goal types, the custom predicate does not filter task selection — it selects from ALL tasks (it's a completion condition, not a filter). The loop works on whatever tasks are available, and finalizes when the predicate returns 0.

### 1. PHASE: Assess Backlog

At the start of each loop iteration:

1. Use `list_projects` to find the project
2. Use `list_tasks` to get all tasks and current status
3. Read `docs/development-plan.md` for dependency data
4. **Filter to effective scope** (see [Goal Predicate Reference](#goal-predicate-reference)):
   - For "All tasks" or "Custom predicate" goals: no filtering — consider all tasks
   - For Epic/Tag/Specific goals: filter to tasks where `in_scope(task)` is true, plus any expanded prerequisites
   - **Recompute the effective scope each iteration** — prerequisites completed in prior iterations no longer need to be in the working set
5. Identify **available tasks**: status `todo` in VK, all dependencies `done`, within the effective scope
6. Check for mutual dependencies — only select tasks that are independent of each other
7. Select up to the configured max parallel tasks, ranked by:
   - Priority (urgent > high > medium > low)
   - Complexity (S > M > L — prefer smaller for faster iteration)
   - Epic order (earlier epics first)
   - Unblocking potential (tasks that unblock other **in-scope** tasks rank higher)

**Scope progress mini-report** — print at the start of each iteration:
```
Goal: Epic 3 [TRK] | In-scope: 5 done, 2 inprogress, 3 todo | 50% complete
```

**Exit condition check:** If NO **in-scope** tasks are available (all are `done`, `inprogress`, or blocked), skip to Phase 5 (Test & Verify) to run the test suite and check `goal_met()`.

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
   - Instruction to update `docs/development-plan.md`: check off acceptance criteria (`[ ]` → `[x]`) and append a Completion Log below the task's AC section
   - Instruction to append a Completion Log to the VK task description when done (using `get_task` then `update_task`)
   - Instruction to mark the task as `inreview` when finished
   - Instruction to commit all work (including the updated development plan) before exiting

   Use the same prompt template as `/work-parallel` (Step 1: update plan, Step 2: log to VK, Step 3: mark inreview).

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

Check `goal_met()` (see [Goal Predicate Reference](#goal-predicate-reference)):

- **All/Epic/Tag/Specific goals:** Check if all originally-scoped tasks are `done`. If YES → proceed to Phase 7 (Finalize). If NO → continue to Phase 6 (Sync & Iterate).
- **Custom predicate goal:** Run the bash command. If it exits 0 → proceed to Phase 7 (Finalize). If non-zero → continue to Phase 6 (Sync & Iterate).

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

3. **Check loop continuation** (goal-aware — see [Goal Predicate Reference](#goal-predicate-reference)):
   - Use `list_tasks` to check the **in-scope** backlog (not the full backlog for scoped goals)
   - For **custom predicate** goals: run the command. If it exits 0 AND tests pass → proceed to Phase 7.
   - For **all other goals**: if there are in-scope `todo` tasks with satisfied dependencies → **go back to Phase 1**
   - If all in-scope remaining tasks are blocked → report what's blocking and **go back to Phase 1** (blocked tasks may have been unblocked by this iteration's completed work)
   - If `goal_met()` is true → proceed to Phase 7

4. **Print iteration summary** (with scope metrics):
   ```
   ## Iteration N Complete

   | Metric | Value |
   |--------|-------|
   | Goal | Epic 3 [TRK] |
   | Tasks completed this iteration | 3 |
   | Tasks failed/skipped | 1 |
   | Merge conflicts auto-resolved | 1 |
   | Test fixes applied | 0 |
   | In-scope done | 5/7 |
   | In-scope remaining | 2 |
   | Prerequisites done | 2/2 |
   | Out-of-scope (ignored) | 19 |
   | Blocked | 1 |

   Proceeding to iteration N+1...
   ```

### 7. PHASE: Finalize

When `goal_met()` is true (see [Goal Predicate Reference](#goal-predicate-reference)):

1. **Final sync:**
   Follow `/sync-plan` one last time to ensure the plan is fully up to date.

2. **Final commit** (goal-aware message):
   ```bash
   # For "All tasks" goal:
   git add -A
   git commit -m "chore: complete autonomous work loop - all tasks done, tests passing

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

   # For scoped goals (epic/tag/specific/custom):
   git add -A
   git commit -m "chore: complete autonomous work loop - Epic 3 [TRK] complete, tests passing

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
   ```

   Adapt the commit message to reflect the goal type:
   - Epic: `"Epic N [TAG] complete"`
   - Tag: `"tag 'X' tasks complete"`
   - Specific: `"tasks 2.1, 2.3, 3.1 complete"`
   - Custom: `"custom goal met (predicate passed)"`

3. **Print final report** (goal-aware):
   ```
   ## Autonomous Work Loop Complete — Epic 3 [TRK]

   | Metric | Value |
   |--------|-------|
   | Goal | Epic 3 [TRK] |
   | Total iterations | 3 |
   | In-scope tasks completed | 5 |
   | Prerequisites completed | 2 |
   | Total tasks failed (need manual review) | 0 |
   | Total merge conflicts auto-resolved | 1 |
   | Total test fix commits | 1 |
   | Final test suite | PASSING |
   | Started at | 2026-03-01 14:30:00 |
   | Finished at | 2026-03-01 15:20:00 |

   ### Tasks Needing Manual Review
   (none)

   ### All Merged Branches
   - task/3.1-setup-database (5 commits)
   - task/3.2-add-models (4 commits)
   - task/3.3-add-migrations (3 commits)
   - task/3.4-seed-data (2 commits)
   - task/1.2-configure-linting (2 commits) [prerequisite]
   - ...

   ### Remaining Out-of-Scope Tasks
   - 19 tasks in other epics not included in this goal
   - Run `/plan-status` for the full backlog view

   ### Next Steps
   - Review the changes: `git log --oneline -20`
   - Check failed tasks manually (if any)
   - Push when ready: `git push`
   - Run `/plan-status` for the final progress view
   - Run `/work-parallel-loop` to continue with remaining tasks
   ```

   For the "All tasks" goal, omit the "Remaining Out-of-Scope Tasks" section and the "continue with remaining tasks" next step (since there are none).

4. **Do NOT push to remote.** Leave that decision to the user.

### 8. Handle Edge Cases

- **No tasks available at start**: Report that all tasks are done or blocked. Run the test suite anyway and finalize if passing.
- **All sessions fail in an iteration**: After retries are exhausted, proceed to merge whatever succeeded. If nothing to merge, skip to test phase. If tests pass with prior work, sync and check for new available tasks.
- **Worktree already exists**: If a worktree/branch already exists for a task, check if it has commits. If yes, reuse it (continue where left off). If no, remove and recreate it.
- **Git worktree add fails**: Try with a different branch name (append `-retry`). If still fails, skip the task this iteration.
- **Loop runs for more than the configured iteration cap without convergence**: Stop and report. Something is likely wrong (circular dependencies, perpetually failing tests, etc.).
- **Disk space**: Not monitored, but if git operations fail unexpectedly, suggest checking disk space.
- **Concurrent users**: This loop assumes it is the only agent modifying the repository. Running multiple loops simultaneously on the same repo will cause conflicts.
- **No test command works**: If the test command fails to execute (not "tests fail" but "command not found"), stop the loop and ask the user to fix the test setup.
- **Scoped task depends on out-of-scope task**: Auto-expand the effective working set to include the prerequisite. This is computed in pre-flight and recomputed each iteration (prerequisites already completed are dropped from the working set).
- **Custom predicate returns 0 before all tasks done**: Finalize immediately — the goal is met even if tasks remain. The custom predicate is the authority on completion.
- **Tag has no matching issues**: Report during pre-flight (step 4) and ask the user for a different tag or goal type. Do not enter the loop with an empty scope.
- **Epic has no remaining todo tasks**: All in-scope tasks are already `done`. Run the test suite once — if tests pass, finalize immediately. If tests fail, attempt fixes and finalize.
- **Scope expansion > 2x original**: Warn the user during pre-flight that the effective working set is significantly larger than the original scope. Suggest "All tasks" instead, but let the user decide.
- **Custom predicate command not found**: Stop the loop during pre-flight (step 4), same as when the test command is not found. Do not enter the loop with an invalid predicate.

### 9. Safety Guardrails

- **Max iterations**: Uses the iteration cap chosen by the user during pre-flight (Step 8). The cap is estimated from the backlog size and parallelism, with a buffer for retries and merge fixes. Hard maximum is 50 to prevent truly runaway loops. If the loop hits the cap without converging, stop and report.
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
