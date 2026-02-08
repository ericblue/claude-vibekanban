---
description: Show available commands and recommended workflow order
version: 0.3-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# VibeKanban Workflow - Command Reference

Display the following command reference to the user:

---

## Typical Flow

```
/generate-prd  →  /prd-review  →  /create-plan  →  /generate-tasks  →  /work-next (repeat)  →  /sync-plan
```

**Quick start:** Have a PRD already? Start at `/prd-review`. Have a plan? Start at `/generate-tasks`. Just want to get coding? Run `/work-next`.

---

## Core Workflow

| Command | Description |
|---------|-------------|
| `/generate-prd` | Generate a PRD from a project idea through guided interview questions |
| `/prd-review` | Analyze an existing PRD, identify gaps, suggest epic breakdown |
| `/create-plan` | Generate a development plan with epics, tasks, complexity, dependencies, and acceptance criteria |
| `/generate-tasks` | Create VibeKanban tasks from the development plan and link them |
| `/sync-plan` | Sync plan with VibeKanban status, detect drift (stale tasks, dependency violations, scope drift) |

## Execution

| Command | Description |
|---------|-------------|
| `/work-task` | Execute a specific task by plan ID or title (fuzzy match). Assembles full context, verifies AC, updates VK. |
| `/work-next` | Find the best available task and execute it end-to-end. Run repeatedly to work through the backlog. |

## Parallel Execution (Experimental)

| Command | Description |
|---------|-------------|
| `/work-parallel` | Analyze backlog, identify independent tasks, set up git worktrees, and launch parallel Claude Code sessions (Tier 1) |
| `/delegate-task` | Delegate a task to a separate VK workspace session with a chosen agent (Tier 2) |
| `/delegate-parallel` | Delegate multiple independent tasks to parallel VK workspace sessions (Tier 2) |
| `/session-status` | Check status of all active work across local worktrees and VK sessions |

## Plan Management

| Command | Description |
|---------|-------------|
| `/plan-status` | Show progress summary without modifying anything (read-only) |
| `/next-task` | Recommend the top 3 tasks to work on next (read-only, doesn't start work) |
| `/add-epic` | Add a new epic to an existing development plan |
| `/close-epic` | Mark an epic as complete after verifying all tasks are done |

## This Command

| Command | Description |
|---------|-------------|
| `/workflow` | Show this command reference |

---

**16 commands total** (12 core + 4 experimental). For detailed documentation, see the project [README](../README.md), [Cookbook](../docs/cookbook.md), and [Architecture](../docs/architecture.md).
