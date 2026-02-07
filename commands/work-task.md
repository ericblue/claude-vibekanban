---
description: Execute a specific task with full context from PRD, plan, and acceptance criteria
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task, mcp__vibe_kanban__update_task
---

# Work on Task

## Context

You are picking up a specific development task and executing it end-to-end. You will assemble all relevant context (PRD, plan, acceptance criteria, dependencies), implement the task, verify it against acceptance criteria, and update VibeKanban status.

## Instructions

### 1. Identify the Task

The user will provide a task ID (e.g., `1.2`, `2.1`). If no ID is provided, ask which task they want to work on.

### 2. Assemble Context

Read these files to build a complete picture of what needs to be done:

1. **Development Plan** (`docs/development-plan.md`):
   - Find the task row in the task table (ID, title, description, priority, complexity, dependencies)
   - Find the task's acceptance criteria in the Task Details section
   - Note which epic this task belongs to and the epic's purpose
   - Identify the VK task ID from the `<!-- vk:ID -->` comment

2. **PRD** (`docs/prd.md` or other PRD file in `docs/`):
   - Read the sections relevant to this task's epic and feature area
   - Understand the broader product context and goals

3. **Existing codebase**:
   - Explore the project structure to understand what exists
   - Read files related to the task's area of concern

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

### 7. Report and Confirm Completion

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

- If user confirms: Use `update_task` to set status to `done`
- If user wants review first: Use `update_task` to set status to `inreview`
- If user wants changes: Make the requested changes, re-verify, and ask again

### 8. Handle Edge Cases

- **Task has no VK ID**: Warn the user and suggest running `/generate-tasks` to link it. Still proceed with implementation.
- **Task is already done**: Inform the user. Ask if they want to redo it.
- **Task is already in progress**: Inform the user. Ask if they want to continue from where it was left.
- **No development plan**: Tell the user to run `/create-plan` first.
- **No PRD**: Proceed with just the plan context, but note the missing context.
- **Implementation blocked**: If you hit a technical blocker, explain the issue clearly and ask the user for guidance rather than guessing.
