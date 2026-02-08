---
description: Merge parallel worktree branches back to main with testing, VK updates, and cleanup
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task
version: 0.5-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Merge Parallel Branches (Experimental)

> **This command is experimental and actively evolving.** Expect changes.

## Context

You are merging branches from parallel worktree sessions (created by `/work-parallel`) back into the main branch. This command automates the merge-test-cleanup cycle that follows parallel execution. It handles sequential merging, optional testing, VK status updates, and worktree cleanup.

**This command is re-runnable.** If it stops partway through (e.g., merge conflict), fix the issue and re-run. It re-reads worktrees and VK status each time, skipping branches that are already merged.

**Run this command from the main project directory** (not from inside a worktree).

## Instructions

### 1. Read Plan and Fetch VK Status

- Read `docs/development-plan.md` if it exists. Extract task IDs, titles, and `<!-- vk:TASK_ID -->` references.
- Use `list_projects` to find the project.
- Use `list_tasks` to get all tasks and their current status.
- Match plan tasks to VK tasks using the `<!-- vk:ID -->` references.

### 2. Detect Worktrees

Run `git worktree list` to find all active worktrees. Parse the output to extract:

- Worktree path
- Branch name (e.g., `task/2.3-add-user-api`)
- Match branch names back to plan task IDs and VK tasks

Also detect the default branch name:

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

If that fails, check for `main` or `master`:

```bash
git branch --list main master | head -1 | tr -d ' *'
```

Use the detected default branch throughout (do not hardcode `main`).

### 3. Identify Merge-Ready Branches

Cross-reference worktree branches with VK task status to determine which are ready to merge:

| VK Status | Action |
|-----------|--------|
| `done` or `inreview` | **Merge-ready** -- include in merge plan |
| `inprogress` | **Skip** -- session may still be running. Report as "still in progress" |
| `todo` | **Skip** -- not started. Report as "not started" |
| No matching VK task | **Flag** -- orphaned worktree. Ask user whether to include |

Also check if the branch has already been merged into the default branch:

```bash
git branch --merged <default-branch> | grep "task/2.3"
```

If already merged, skip it and report as "already merged" (useful for re-runs after partial completion).

### 4. Present the Merge Plan

Show the user what will be merged, in what order, and what will be skipped:

```
## Merge Plan

### Ready to merge (3 branches)

| # | Task | Branch | VK Status | Commits | Strategy |
|---|------|--------|-----------|---------|----------|
| 1 | 4.2 - Add logging | task/4.2-add-logging | done | 3 | merge |
| 2 | 3.1 - Setup database | task/3.1-setup-database | inreview | 5 | merge |
| 3 | 2.3 - Add user API | task/2.3-add-user-api | inreview | 8 | merge |

### Skipped

| Task | Branch | Reason |
|------|--------|--------|
| 5.1 - Write tests | task/5.1-write-tests | Still inprogress |

### Options

1. **Test command** (optional): Provide a command to run after each merge (e.g., `npm test`, `pytest`)
   - Leave blank to skip testing
2. **Merge strategy**:
   - **merge** (default) -- standard `git merge`
   - **rebase** -- `git rebase` onto default branch, then fast-forward merge
3. Confirm to proceed, or adjust the plan
```

**Ordering:** Sort merge-ready branches by simplest first (fewest commits ahead of default branch). This minimizes cascading conflicts.

**Do not proceed until the user explicitly confirms.** Allow the user to:
- Remove branches from the merge plan ("skip 2")
- Change merge order ("merge 3 first")
- Provide a test command
- Choose merge strategy (merge or rebase)

### 5. Execute Merges Sequentially

For each branch in the confirmed order:

**Pre-merge checks:**

1. Verify working tree is clean on the default branch:
   ```bash
   git status --porcelain
   ```
   If dirty, **abort** and tell the user to commit or stash changes first.

2. Ensure we're on the default branch with latest changes:
   ```bash
   git checkout <default-branch>
   git pull --ff-only
   ```

**Merge (default strategy):**

```bash
git merge task/2.3-add-user-api --no-edit
```

**Rebase strategy (if user chose rebase):**

```bash
# Rebase the feature branch onto default branch
git checkout task/2.3-add-user-api
git rebase <default-branch>
# If rebase succeeds, fast-forward merge
git checkout <default-branch>
git merge task/2.3-add-user-api --ff-only
```

**On merge/rebase conflicts:**

**STOP immediately.** Do not attempt to auto-resolve conflicts. Report:

```
## Conflict during merge of task/2.3-add-user-api

Conflicting files:
- src/routes/index.ts
- src/config/registry.ts

To resolve:
1. Fix the conflicts in the listed files
2. Run `git add <resolved-files> && git commit` (for merge) or `git add <resolved-files> && git rebase --continue` (for rebase)
3. Re-run `/merge-parallel` to continue with remaining branches

Already merged in this run:
- task/4.2-add-logging (success)
- task/3.1-setup-database (success)
```

The user resolves conflicts manually and re-runs `/merge-parallel`. Already-merged branches will be detected and skipped.

**Post-merge testing (if test command provided):**

Run the test command after each successful merge:

```bash
<test-command>
```

If tests fail, present options:

```
## Tests failed after merging task/2.3-add-user-api

Test output: [show relevant output]

Options:
1. **Continue** -- keep the merge and proceed to next branch
2. **Revert** -- undo the merge (`git revert -m 1 HEAD`) and skip this branch
3. **Stop** -- pause here so you can investigate and fix
```

Wait for the user to choose before proceeding.

**After each successful merge, report progress:**

```
Merged task/4.2-add-logging into <default-branch> (1/3)
```

### 6. Update Task Status in VK

After all merges complete (or after each successful merge), update VK:

- For tasks that were `inreview`, mark as `done` using `update_task`
- For tasks already `done`, no update needed

Report results:

```
## VK Status Updates

| Task | Previous | Updated | Result |
|------|----------|---------|--------|
| 4.2 - Add logging | done | done | No change needed |
| 3.1 - Setup database | inreview | done | Updated |
| 2.3 - Add user API | inreview | done | Updated |
```

**Non-blocking on failure:** If a VK update fails, warn the user but continue. The merge is already done in git -- VK status can be updated manually.

### 7. Offer Cleanup

After merges and VK updates, offer to clean up:

```
## Cleanup

The following can be removed:

### Worktrees
- ../myproject-worktrees/task-4.2-add-logging/
- ../myproject-worktrees/task-3.1-setup-database/
- ../myproject-worktrees/task-2.3-add-user-api/

### Merged branches
- task/4.2-add-logging
- task/3.1-setup-database
- task/2.3-add-user-api

### Screen/tmux sessions (if any remain)
- claude-task-4.2
- claude-task-3.1
- claude-task-2.3

Clean up all? Or select specific items to remove.
```

**Wait for user confirmation before cleanup.** Then execute:

```bash
# Remove worktrees
git worktree remove ../myproject-worktrees/task-4.2-add-logging
git worktree remove ../myproject-worktrees/task-3.1-setup-database
git worktree remove ../myproject-worktrees/task-2.3-add-user-api

# Delete merged branches
git branch -d task/4.2-add-logging
git branch -d task/3.1-setup-database
git branch -d task/2.3-add-user-api

# Kill leftover screen sessions (if any)
screen -X -S claude-task-4.2 quit 2>/dev/null
screen -X -S claude-task-3.1 quit 2>/dev/null
screen -X -S claude-task-2.3 quit 2>/dev/null

# Or tmux sessions
tmux kill-session -t claude-task-4.2 2>/dev/null
tmux kill-session -t claude-task-3.1 2>/dev/null
tmux kill-session -t claude-task-2.3 2>/dev/null

# Prune stale worktree references
git worktree prune
```

If the worktrees directory is now empty, offer to remove it:

```bash
rmdir ../myproject-worktrees 2>/dev/null
```

### 8. Suggest Next Steps

After completion, suggest:

```
## Next Steps

- Run `/sync-plan` to update the development plan with completed tasks
- Run `/plan-status` to see overall progress
- Run `/work-parallel` to start the next batch of independent tasks
- If more branches remain (skipped as in-progress), check back with `/session-status`
```

### 9. Handle Edge Cases

- **No worktrees found**: Report "No worktrees detected. Nothing to merge. If you expected worktrees, check `git worktree list`."
- **No merge-ready branches**: All worktree branches are still `inprogress` or `todo`. Report status and suggest checking back later or using `/session-status`.
- **Dirty working tree on default branch**: Abort before any merge. Tell the user to commit or stash first.
- **Partial completion (re-run)**: On re-run, already-merged branches are detected via `git branch --merged` and skipped. This makes the command safe to re-run after resolving conflicts.
- **Default branch detection**: Use `git symbolic-ref refs/remotes/origin/HEAD` first, fall back to checking for `main` or `master`. Never hardcode a branch name.
- **Worktrees without matching VK tasks**: Flag as orphaned. Ask the user whether to include them in the merge plan or skip.
- **No development plan file**: Work from VK tasks only. Branch-to-task matching relies on branch naming conventions (`task/<id>-<slug>`).
- **User runs from inside a worktree**: Detect this (current directory is inside a worktree path from `git worktree list`) and warn: "You appear to be inside a worktree. Run `/merge-parallel` from the main project directory instead."
