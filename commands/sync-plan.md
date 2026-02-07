---
description: Sync development plan with VibeKanban task status (VK is source of truth)
allowed-tools: mcp__vibekanban__list_projects, mcp__vibekanban__list_tasks, mcp__vibekanban__get_task, mcp__vibekanban__update_task
---

# Sync Development Plan with VibeKanban

## Context

You are synchronizing the development plan (`docs/development-plan.md`) with VibeKanban task status. **VibeKanban is the source of truth** - task status in VK will update the plan, including epic progress percentages.

## Current Plan

!`cat docs/development-plan.md 2>/dev/null`

## Instructions

### 1. Parse the Development Plan

Extract:
- **Epics**: Name, current status, current progress percentage
- **Tasks**: ID, title, priority, VK task ID (from `<!-- vk:TASK_ID -->`)
- **Acceptance Criteria**: Checkbox status per epic

### 2. Fetch VibeKanban Status

For each task that has a VK task ID:
- Use `get_task` to fetch current status
- Note: VK statuses typically map as:
  - `todo` / `backlog` / `open` → Not started
  - `in_progress` / `in-progress` → In progress
  - `done` / `completed` / `closed` → Complete

### 3. Calculate Epic Progress

For each epic:
1. Count total tasks in the epic
2. Count completed tasks (based on VK status)
3. Calculate percentage: `(completed / total) * 100`
4. Determine epic status:
   - 0% complete → `NOT STARTED`
   - 1-99% complete → `IN PROGRESS`
   - 100% complete → `COMPLETE`

### 4. Identify Discrepancies

Compare plan with VK:
- **Status changes** - Tasks that changed status since last sync
- **Unlinked tasks** - Tasks in plan without VK ID (need `/generate-tasks`)
- **Orphaned tasks** - Tasks in VK not found in plan

### 5. Update the Plan

Modify `docs/development-plan.md`:

1. **Update Completion Status Summary table** - New percentages and statuses
2. **Update Epic headers** - Change `(NOT STARTED)` to `(IN PROGRESS)` or `(COMPLETE)`
3. **Update "Last synced" date** in header
4. **Add changelog entry** with summary of changes

### 6. Report Changes

Provide a sync summary:

```markdown
## Sync Summary

**Synced at:** [timestamp]
**VibeKanban Project:** [project name]

### Epic Progress

| Epic | Previous | Current | Change |
|------|----------|---------|--------|
| 1. Foundation | 0% | 50% | +50% |
| 2. Core Features | 0% | 0% | - |

### Task Status Changes

| ID | Task | Previous | Current |
|----|------|----------|---------|
| 1.1 | Set up project | Not Started | Complete |
| 1.2 | Configure DB | Not Started | In Progress |

### Warnings

- [X] tasks in plan without VK ID (run /generate-tasks)
- [Y] tasks in VK not found in plan

### Overall Progress

- **Total Epics:** X
- **Epics Complete:** Y
- **Total Tasks:** Z
- **Tasks Complete:** W (N%)
- **Tasks In Progress:** V
- **Tasks Remaining:** U
```

## Updating Epic Status in Plan

When updating the plan, change epic headers like this:

**Before:**
```markdown
## Epic 1: Foundation (NOT STARTED)
```

**After (if 50% done):**
```markdown
## Epic 1: Foundation (IN PROGRESS)
```

**After (if 100% done):**
```markdown
## Epic 1: Foundation (COMPLETE)
```

Also update the summary table:
```markdown
| 1. Foundation | Complete | 100% |
```

## Handling Edge Cases

### Tasks without VK IDs
Flag these and suggest running `/generate-tasks`:
```
Warning: 3 tasks found without VibeKanban IDs
  - 2.4 Implement caching
  - 2.5 Add logging
  - 3.1 Create UI
Run /generate-tasks to link these tasks.
```

### New tasks added to plan
If user added tasks manually, offer to:
1. Create them in VK (like `/generate-tasks`)
2. Leave them as local-only tasks

### Deleted VK tasks
If a VK task ID no longer exists:
- Note it in the sync report
- Ask user if task should be removed from plan or recreated

### Acceptance Criteria
If all tasks in an epic are complete, remind user to verify acceptance criteria are met before marking epic as truly complete.

## Changelog Entry Format

Add to the changelog section:
```markdown
- **[date]**: Synced with VibeKanban - Epic 1 now 50% complete (2/4 tasks done); Epic 2 started
```

## Best Practices

- Run `/sync-plan` before starting work to get latest status
- Run `/sync-plan` after completing tasks in VK
- The plan serves as documentation; VK serves as the work tracker
- Commit the updated plan to version control after syncing
- Use `/plan-status` for quick checks without modifying the plan
