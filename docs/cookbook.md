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

**Q: Can parallel tasks cause merge conflicts?**

A: Yes. Each parallel session works on its own branch. When merging back to main, conflicts are possible if tasks touch related files -- especially shared registries, route tables, index/barrel files, and config files. Independent tasks that modify different files merge cleanly. Use the rebase-then-merge pattern: merge one branch, rebase the next onto the updated main, resolve conflicts, repeat.

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

| Command | Input | Description |
|---------|-------|-------------|
| `/work-parallel` | Task IDs (optional) | Parallel local sessions via git worktrees |
| `/delegate-task` | Task ID + agent type | Delegate to VK workspace session |
| `/delegate-batch` | Task IDs + agent type | Delegate multiple tasks to VK sessions |
| `/session-status` | None | Check active workspace sessions |
