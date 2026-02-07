---
description: Add a new epic to an existing development plan
allowed-tools: mcp__vibe_kanban__list_projects, mcp__vibe_kanban__list_tasks
---

# Add Epic

## Context

You are adding a new epic to an existing development plan. This is useful when scope expands or new feature areas are identified after initial planning.

## Current Plan

Read the file `docs/development-plan.md` to get the current plan contents. If the file doesn't exist, inform the user and suggest running `/create-plan` first.

## Instructions

### 1. Gather Epic Information

Ask the user for (if not provided):
- **Epic name** - Clear, descriptive name for the epic
- **Description** - Brief description of what this epic covers
- **Tasks** - List of tasks to include (can be added later)
- **Priority** - Where this epic falls in priority order
- **Insertion point** - Which epic number it should be (or append at end)

### 2. Determine Epic Number

Based on existing epics:
- If inserting between existing epics, renumber subsequent epics
- If appending, use next available number
- Update all task IDs accordingly if renumbering

### 3. Create Epic Structure

Format the new epic:

```markdown
---

## Epic [N]: [Epic Name] (NOT STARTED)

[Description of what this epic covers and why it was added]

### Acceptance Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]

### Tasks

| ID | Title | Description | Priority | Status |
|----|-------|-------------|----------|--------|
| N.1 | [Task title] | [Description] | High | <!-- vk: --> |
| N.2 | [Task title] | [Description] | Medium | <!-- vk: --> |

---
```

### 4. Update the Plan

1. **Insert the new epic** at the appropriate location
2. **Update the Completion Status Summary** table to include the new epic
3. **Renumber subsequent epics** if inserting (not appending)
4. **Update task IDs** for any renumbered epics
5. **Add changelog entry** documenting the addition

### 5. Update Summary Table

Add the new epic to the summary:

```markdown
| [N]. [Epic Name] | Not Started | 0% |
```

### 6. Changelog Entry

Add to changelog:
```markdown
- **[date]**: Added Epic [N]: [Epic Name] - [brief reason for addition]
```

## Example

**User request:** "Add a new epic for API documentation between Epic 2 and Epic 3"

**Before:**
```markdown
## Completion Status Summary

| Epic | Status | Progress |
|------|--------|----------|
| 1. Foundation | Complete | 100% |
| 2. Core Features | In Progress | 50% |
| 3. Polish | Not Started | 0% |
```

**After:**
```markdown
## Completion Status Summary

| Epic | Status | Progress |
|------|--------|----------|
| 1. Foundation | Complete | 100% |
| 2. Core Features | In Progress | 50% |
| 3. API Documentation | Not Started | 0% |
| 4. Polish | Not Started | 0% |
```

Note: Epic 3 (Polish) became Epic 4, and all its task IDs changed from 3.x to 4.x.

## Output

After adding the epic:

1. **Confirm the addition** - Show the new epic structure
2. **Show updated summary table** - Display the new completion status summary
3. **List renumbered items** - If any epics/tasks were renumbered, list them
4. **Next steps** - Remind user to:
   - Add more tasks with `/add-epic` or by editing the plan directly
   - Run `/generate-tasks` to create VK tasks for the new epic
   - Review the epic's acceptance criteria

## Handling Task Renumbering

If inserting an epic causes renumbering:

1. Update all task IDs in affected epics (e.g., 3.1 → 4.1)
2. If tasks were already linked to VK, their VK IDs remain the same
3. Update the task titles in VK to reflect new IDs (optional but recommended)
4. Note the renumbering in the changelog

```markdown
- **[date]**: Added Epic 3: API Documentation; renumbered Epic 3 (Polish) to Epic 4
```
