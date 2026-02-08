---
description: Recommend the best next task to work on based on priority and dependencies
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task
version: 0.3.1-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Next Task Recommendation

## Context

You are analyzing the development plan and VibeKanban task status to recommend the best next task to work on. You consider dependencies, priorities, and current progress to give an informed recommendation.

## Current Plan

Read the file `docs/development-plan.md` to get the current plan contents. If the file doesn't exist, inform the user and suggest running `/create-plan` first.

## Instructions

### 1. Parse the Development Plan

Extract from `docs/development-plan.md`:
- **All tasks** with their ID, title, priority, complexity, dependencies (Depends On column), and VK task ID
- **Epic structure** to understand grouping and order
- **Dependencies** both within and across epics

If the plan file doesn't exist, inform the user and suggest running `/create-plan` first.

### 2. Fetch Current Task Status from VibeKanban

- Use `list_projects` to find the project
- Use `list_tasks` to get all tasks and their current status
- Match VK tasks to plan tasks using the `<!-- vk:TASK_ID -->` references

### 3. Determine Available Tasks

A task is **available** if it meets ALL of these criteria:
- Status is `todo` (not started, not in progress, not done)
- All tasks listed in its "Depends On" column are `done` / `completed` in VK
- It has a VK task ID (linked to VibeKanban)

If a task has no VK ID, still consider it but note it needs `/generate-tasks` first.

### 4. Rank Available Tasks

Score and rank available tasks using these criteria (in priority order):

1. **Dependency-free first** - Tasks with no dependencies (or all dependencies satisfied) rank higher
2. **Priority** - High > Medium > Low
3. **Complexity** - Prefer smaller tasks (S > M > L > XL) when priorities are equal, to maintain momentum
4. **Epic order** - Earlier epics first (Epic 1 before Epic 2) to maintain logical build order
5. **Unblocks others** - Tasks that are dependencies for many other tasks get a boost

### 5. Present Recommendations

Display the top 3 recommendations (or fewer if less are available):

```markdown
## Next Task Recommendations

### #1 Recommended: [Task ID] - [Task Title]
- **Epic:** [Epic name]
- **Priority:** [High/Medium/Low]
- **Complexity:** [S/M/L/XL]
- **Why:** [Reasoning - e.g., "High priority, no dependencies, unblocks 3 other tasks"]

### #2: [Task ID] - [Task Title]
- **Epic:** [Epic name]
- **Priority:** [High/Medium/Low]
- **Complexity:** [S/M/L/XL]
- **Why:** [Reasoning]

### #3: [Task ID] - [Task Title]
- **Epic:** [Epic name]
- **Priority:** [High/Medium/Low]
- **Complexity:** [S/M/L/XL]
- **Why:** [Reasoning]

---

**Currently in progress:** [List any tasks currently marked as inprogress]
**Blocked tasks:** [List tasks waiting on incomplete dependencies]
```

### 6. Offer to Start

After presenting recommendations, ask the user:

> Would you like me to start working on any of these? I can mark the task as "in progress" in VibeKanban.

If the user confirms:
- Use `update_task` to set the selected task's status to `inprogress`
- Confirm the update was made

### 7. Handle Edge Cases

- **No available tasks:** All tasks are done, in progress, or blocked. Report what's blocking progress.
- **No development plan:** Tell the user to run `/create-plan` first.
- **No VK project:** Tell the user to run `/generate-tasks` to create VK tasks.
- **All tasks in progress:** Suggest finishing current work before starting new tasks. List what's in progress.
- **Dependency cycle detected:** Flag it as an issue in the plan that needs manual resolution.
