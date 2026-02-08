---
description: Execute a specific task with full context from PRD, plan, and acceptance criteria
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task
version: 0.3.1-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Work on Task

## Context

You are picking up a specific development task and executing it end-to-end. You will assemble all relevant context (PRD, plan, acceptance criteria, dependencies), implement the task, verify it against acceptance criteria, and update VibeKanban status.

## Instructions

### 1. Identify the Task

The user can identify a task in any of these ways:

- **Plan task ID** (e.g., `1.2`, `2.1`) - Look it up in the development plan task tables
- **Task title or partial title** (e.g., `"auth"`, `"set up database"`) - Fuzzy match against both the development plan and VibeKanban tasks
- **No input provided** - List available tasks and ask which one to work on

**Resolution logic:**

1. If the input matches a plan task ID pattern (digits.digits), look it up in the plan
2. Otherwise, treat it as a title search:
   - Use `list_projects` and `list_tasks` to fetch all VK tasks
   - Also check task titles in `docs/development-plan.md` if it exists
   - Find tasks whose title contains the search text (case-insensitive)
   - If multiple matches, show them and ask the user to pick one
   - If exactly one match, confirm it with the user before proceeding
3. If no match is found, show available tasks and ask the user to clarify

This allows working on tasks that were created directly in VibeKanban and may not exist in the development plan.

### 2. Assemble Context

Read these files to build a complete picture of what needs to be done:

1. **Development Plan** (`docs/development-plan.md`) -- if the task exists in the plan:
   - Find the task row in the task table (ID, title, description, priority, complexity, dependencies)
   - Find the task's acceptance criteria in the Task Details section
   - Note which epic this task belongs to and the epic's purpose
   - Identify the VK task ID from the `<!-- vk:ID -->` comment

2. **VibeKanban task** -- if the task exists in VK (or was matched by title):
   - Use `get_task` to fetch the full task details including title and description
   - Use the VK description as context, especially for tasks not in the plan

3. **PRD** (`docs/prd.md` or other PRD file in `docs/`):
   - Read the sections relevant to this task's feature area
   - Understand the broader product context and goals

4. **Existing codebase**:
   - Explore the project structure to understand what exists
   - Read files related to the task's area of concern

Note: Not all context sources will exist for every task. A task created directly in VK may have no plan entry or AC. In that case, use the VK task title and description as the primary context, and ask the user for any missing acceptance criteria before starting implementation.

### 3. Check Dependencies

- Parse the "Depends On" column for this task
- If the task has dependencies, use `list_tasks` / `get_task` to verify each dependency is `done` in VK
- If dependencies are NOT satisfied:
  - List which dependencies are incomplete
  - Warn the user that proceeding may cause issues
  - Ask if they want to proceed anyway or work on a different task
- If dependencies are satisfied (or task has none), proceed

### 4. Mark Task In Progress

- Use `list_projects` and `list_tasks` to find the VK task
- Use `update_task` to set status to `inprogress`
- Confirm to the user: "Marked task [ID] - [Title] as in progress in VibeKanban."

### 5. Implement the Task

Work through the implementation:

- **Plan your approach** - Before writing code, briefly outline what you'll do
- **Make incremental changes** - Work in small, testable steps
- **Follow existing patterns** - Match the codebase's conventions, style, and architecture
- **Stay focused** - Only implement what this task requires, nothing more

### 6. Verify Against Acceptance Criteria

After implementation, go through each acceptance criterion from the Task Details section:

```
## Verification: [Task ID] - [Task Title]

- [x] [Criterion 1] - [How you verified it]
- [x] [Criterion 2] - [How you verified it]
- [ ] [Criterion 3] - [Why this couldn't be verified / what's needed]
```

Run any relevant tests, builds, or checks to validate the criteria. If any criterion cannot be satisfied, explain why and ask the user how to proceed.

### 7. Report, Log Results, and Confirm Completion

Present a summary to the user:

```
## Task Complete: [ID] - [Title]

### Changes Made
- [File 1]: [What changed]
- [File 2]: [What changed]

### Acceptance Criteria
- [x] All criteria met (or list exceptions)

### Notes
- [Any observations, follow-ups, or things to watch for]
```

Then ask: **"Should I mark this task as done in VibeKanban?"**

**Before updating the task status**, append a completion log to the task description in VK:

1. Use `get_task` to read the current task description
2. Use `update_task` to set the description to the original description plus a completion log section appended at the end. Use this format:

```
---
## Completion Log
**Agent:** Claude Code (interactive)
**Branch:** main (or feature branch name if applicable)

### Changes
- Modified src/routes/users.ts (added validation)
- Created tests/users.test.ts (new file)

### Summary
Implemented input validation for user endpoints...

### Acceptance Criteria
- [x] GET /users/:id returns user profile
- [x] Input validation rejects malformed data
```

3. Then update the status based on user choice:
   - If user confirms: Use `update_task` to set status to `done`
   - If user wants review first: Use `update_task` to set status to `inreview`
   - If user wants changes: Make the requested changes, re-verify, and ask again

**Non-blocking on failure:** If `update_task` fails when appending the completion log, warn but continue — proceed to update the task status. Logging is best-effort; it should never block the workflow.

### 8. Handle Edge Cases

- **VK-only task (not in plan)**: Task was created directly in VibeKanban. Use the VK title and description as context. Ask the user for acceptance criteria if none are apparent. Skip dependency checking.
- **Task has no VK ID**: Warn the user and suggest running `/generate-tasks` to link it. Still proceed with implementation.
- **Multiple title matches**: Show all matches with their status and source (plan, VK, or both). Ask the user to pick one.
- **Task is already done**: Inform the user. Ask if they want to redo it.
- **Task is already in progress**: Inform the user. Ask if they want to continue from where it was left.
- **No development plan**: Check VK directly for tasks. If VK has tasks, work from those.
- **No PRD**: Proceed with available context, but note the missing context.
- **Implementation blocked**: If you hit a technical blocker, explain the issue clearly and ask the user for guidance rather than guessing.
