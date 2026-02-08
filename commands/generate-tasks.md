---
description: Generate VibeKanban tasks from the development plan
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__create_task, mcp__vibe_kanban__list_tasks, mcp__vibe_kanban__get_task
version: 0.3.1-preview
date: 2026-02-07
author: Eric Blue (https://github.com/ericblue)
repository: https://github.com/ericblue/claude-vibekanban
---

# Generate VibeKanban Tasks

## Context

You are creating tasks in VibeKanban based on the development plan. This links the plan to actual trackable tasks, preserving epic organization and priorities.

## Prerequisites Check

Read the file `docs/development-plan.md` to get the current plan contents. If the file doesn't exist, inform the user and suggest running `/create-plan` first.

## Instructions

1. **Read the development plan** - Parse `docs/development-plan.md` to extract:
   - All epics and their metadata
   - All tasks with their hierarchical IDs (e.g., 1.1, 2.3)
   - Task priorities (High, Medium, Low)
   - Task descriptions

2. **Get or confirm the VibeKanban project** - Use `list_projects` to find the correct project
   - If multiple projects exist, ask the user which one to use
   - If no project exists, inform the user they need to create one in VibeKanban first
   - Update the plan's "VibeKanban Project ID" field if not set

3. **Check for existing tasks** - Use `list_tasks` to see what already exists
   - Avoid creating duplicate tasks
   - Match by title similarity or task ID in title

4. **Create tasks in VibeKanban** - For each uncreated task in the plan:
   - Use `create_task` with the project_id
   - Title format: `[ID] Task title` (e.g., "1.1 Set up project structure")
   - Include epic name, priority, and description in the task body

5. **Update the plan with task IDs** - After creating each task:
   - Update the `<!-- vk: -->` placeholder with `<!-- vk:TASK_ID -->`
   - This enables bidirectional sync

6. **Update the changelog** - Add an entry noting tasks were generated

## Task Creation Format

When creating tasks, format the description as:

```
Epic: [Epic Number]. [Epic Name]
Priority: [High/Medium/Low]
Task ID: [Hierarchical ID]

[Task description from plan]

---
Source: docs/development-plan.md
```

## Example Transformation

**Before (in plan):**
```markdown
| 1.1 | Set up project structure | Initialize with proper folder structure | High | <!-- vk: --> |
```

**After task creation:**
```markdown
| 1.1 | Set up project structure | Initialize with proper folder structure | High | <!-- vk:abc123 --> |
```

**Task created in VibeKanban:**
- Title: `1.1 Set up project structure`
- Description:
  ```
  Epic: 1. Foundation/Setup
  Priority: High
  Task ID: 1.1

  Initialize with proper folder structure

  ---
  Source: docs/development-plan.md
  ```

## Priority Mapping

If VibeKanban supports priority or labels, map as follows:
- `High` → priority: high (or label: "high-priority")
- `Medium` → priority: medium (or label: "medium-priority")
- `Low` → priority: low (or label: "low-priority")

Also consider adding epic labels:
- `Epic-1`, `Epic-2`, etc.

## Output

After generating tasks:

1. **Summary** - Report:
   - How many tasks were created vs already existed
   - Breakdown by epic
   - Any errors encountered

2. **Task Mapping** - Show the mapping:
   ```
   | Plan ID | Title | VK Task ID | Status |
   |---------|-------|------------|--------|
   | 1.1 | Set up project | abc123 | Created |
   | 1.2 | Configure DB | def456 | Created |
   | 2.1 | Implement API | - | Already exists |
   ```

3. **Next Steps** - Remind user they can:
   - View tasks in VibeKanban
   - Use `/sync-plan` to keep the plan updated with task status
   - Use `/plan-status` for a quick progress overview
   - Check off tasks in VibeKanban (VK is source of truth)

## Error Handling

- If no project is found, provide instructions to create one in VibeKanban
- If task creation fails, report the error and continue with remaining tasks
- If the plan has no parseable tasks, explain the expected format
- If a task ID format is unexpected, flag it but continue processing
