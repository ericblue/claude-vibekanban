---
description: Find the best next task and execute it end-to-end
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task
version: 0.3-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Work on Next Task

## Context

You are finding the best next task to work on and then executing it. This combines task recommendation (like `/next-task`) with task execution (like `/work-task`) into a single workflow.

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

### 3. Select the Best Task

A task is **available** if:
- Status is `todo` in VK (not started, not in progress, not done)
- All tasks in its "Depends On" column are `done` / `completed` in VK

Rank available tasks by:
1. **Dependency-free first** - No blockers
2. **Priority** - High > Medium > Low
3. **Complexity** - Prefer smaller tasks (S > M) for momentum
4. **Epic order** - Earlier epics first
5. **Unblocks others** - Tasks that are dependencies for other tasks get a boost

### 4. Present the Recommendation

Show the user the selected task:

```
## Recommended Next Task

### [Task ID] - [Task Title]
- **Epic:** [Epic name]
- **Priority:** [High/Medium/Low]
- **Complexity:** [S/M/L/XL]
- **Dependencies:** [All satisfied / None]
- **Why this task:** [Brief reasoning]

### Acceptance Criteria
- [ ] [Criterion 1 from Task Details]
- [ ] [Criterion 2 from Task Details]

Shall I start working on this task?
```

Wait for user confirmation before proceeding. If the user wants a different task, ask which one they'd prefer.

### 5. Execute the Task

Once the user confirms, follow the full execution workflow:

**a. Read the PRD** (`docs/prd.md` or other PRD in `docs/`) for broader product context relevant to this task.

**b. Explore the codebase** to understand existing structure and patterns.

**c. Mark as in progress** - Use `update_task` to set status to `inprogress`. Confirm to the user.

**d. Implement** - Plan your approach, then make incremental changes. Stay focused on this task only. Follow existing codebase conventions.

**e. Verify** - Check each acceptance criterion from Task Details:

```
## Verification: [Task ID] - [Task Title]

- [x] [Criterion 1] - [How verified]
- [x] [Criterion 2] - [How verified]
```

Run relevant tests, builds, or checks.

**f. Report and confirm** - Present a summary of changes and verification results:

```
## Task Complete: [ID] - [Title]

### Changes Made
- [File 1]: [What changed]
- [File 2]: [What changed]

### Acceptance Criteria
- [x] All criteria met (or list exceptions)

### Notes
- [Any observations or follow-ups]
```

Ask: **"Should I mark this task as done in VibeKanban?"**

- User confirms: Set status to `done`
- User wants review: Set status to `inreview`
- User wants changes: Iterate, re-verify, ask again

### 6. Suggest What's Next

After completing the task, briefly note what the next available task would be (without full analysis). This primes the user to run `/work-next` again if they want to keep going.

```
**Up next:** [Task ID] - [Task Title] ([Priority], [Complexity]) is now unblocked and ready.
```

### 7. Handle Edge Cases

- **No available tasks**: All tasks are done, in progress, or blocked. Report what's blocking progress.
- **No VK project**: Tell the user to run `/generate-tasks` first.
- **All tasks in progress**: Suggest finishing current work. List what's in progress.
- **User declines recommendation**: Ask what they'd prefer to work on, or show top 3 alternatives.
