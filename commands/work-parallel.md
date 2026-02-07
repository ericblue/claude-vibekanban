---
description: Analyze backlog, identify independent tasks, set up worktrees, and launch parallel sessions
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task, mcp__vibe_kanban__list_repos
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

### 7. Launch Sessions

Explain to the user how to launch Claude Code sessions in each worktree. The launch mechanism depends on what's available:

**Option A: Agent Teams (preferred if available)**

If Claude Code Agent Teams is enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`), suggest:

```
Create an agent team with 3 teammates. Each teammate should work in a separate worktree:
- Teammate 1: cd to ../myproject-worktrees/task-2.3-add-user-api/ and implement task 2.3 (Add user API). Acceptance criteria: [list AC]. Mark as inreview in VK when done.
- Teammate 2: cd to ../myproject-worktrees/task-3.1-setup-database/ and implement task 3.1 (Setup database). Acceptance criteria: [list AC]. Mark as inreview in VK when done.
- Teammate 3: cd to ../myproject-worktrees/task-4.2-add-logging/ and implement task 4.2 (Add logging). Acceptance criteria: [list AC]. Mark as inreview in VK when done.
```

**Option B: Headless mode**

Provide commands the user can run in separate terminals:

```bash
cd ../myproject-worktrees/task-2.3-add-user-api && claude -p "Implement task 2.3: Add user API. [Include full context: description, AC, relevant PRD sections]. When done, use update_task to mark as inreview in VibeKanban."

cd ../myproject-worktrees/task-3.1-setup-database && claude -p "Implement task 3.1: Setup database. [Include full context]. When done, use update_task to mark as inreview in VibeKanban."

cd ../myproject-worktrees/task-4.2-add-logging && claude -p "Implement task 4.2: Add logging. [Include full context]. When done, use update_task to mark as inreview in VibeKanban."
```

**Option C: Manual terminals**

Provide instructions for the user to open separate terminals:

```
Open 3 terminal windows and run `claude` in each worktree:

Terminal 1: cd ../myproject-worktrees/task-2.3-add-user-api && claude
Terminal 2: cd ../myproject-worktrees/task-3.1-setup-database && claude
Terminal 3: cd ../myproject-worktrees/task-4.2-add-logging && claude

In each session, use /work-task [task-id] to start the task.
```

### 8. Provide Post-Execution Guidance

After launching sessions, remind the user about the review-before-merge workflow:

```
## Next Steps

1. **Monitor**: Check progress in the VibeKanban board or with `/plan-status`
2. **Review**: When tasks move to `inreview`, test each branch:
   - cd into the worktree, run tests, verify behavior
   - Use VK's diff view and inline commenting for code review
3. **Merge sequentially**:
   - Merge the first branch to main
   - Rebase the next branch onto main: `git rebase main`
   - Resolve any conflicts (watch for shared files: registries, configs, index files)
   - Repeat for remaining branches
4. **Sync**: Run `/sync-plan` after all branches are merged
5. **Clean up**: Remove worktrees when done:
   - `git worktree remove ../myproject-worktrees/task-2.3-add-user-api`
   - Or remove all: `rm -rf ../myproject-worktrees/ && git worktree prune`
```

### 9. Handle Edge Cases

- **No available tasks**: All tasks are done, in progress, or blocked. Report what's blocking progress.
- **Only 1 available task**: Suggest using `/work-next` instead -- parallelism adds overhead with no benefit for a single task.
- **No development plan**: Check VK directly for tasks. Warn that dependency analysis is not possible without a plan.
- **No VK project**: Tell the user to run `/generate-tasks` first.
- **Worktree already exists**: If a worktree/branch already exists for a task, inform the user and ask whether to reuse it or create a fresh one.
- **User wants more than 3**: Allow it, but warn about resource consumption: "Each session consumes tokens and local compute. Running [N] parallel sessions will use significantly more resources than the default 3."
- **Git worktree command fails**: Check if the branch name already exists (`git branch --list`). If so, suggest a different name or ask the user to delete the stale branch.
