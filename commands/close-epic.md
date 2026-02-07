---
description: Mark an epic as complete and update the development plan
allowed-tools: mcp__vibekanban__list_projects, mcp__vibekanban__list_tasks, mcp__vibekanban__get_task
---

# Close Epic

## Context

You are marking an epic as complete in the development plan. This involves verifying all tasks are done, checking acceptance criteria, and updating the plan documentation.

## Current Plan

Read the file `docs/development-plan.md` to get the current plan contents. If the file doesn't exist, inform the user and suggest running `/create-plan` first.

## Instructions

### 1. Identify the Epic

If the user didn't specify which epic, show them the current epic status and ask:

```markdown
## Current Epic Status

| Epic | Status | Progress |
|------|--------|----------|
| 1. Foundation | Complete | 100% |
| 2. Core Features | In Progress | 80% |
| 3. Supporting | Not Started | 0% |

Which epic would you like to close?
```

### 2. Verify Task Completion

For the specified epic:
1. List all tasks in the epic
2. Check each task's status in VibeKanban
3. Identify any incomplete tasks

If incomplete tasks exist:
```markdown
## Cannot Close Epic

Epic 2: Core Features has 2 incomplete tasks:

| ID | Task | VK Status |
|----|------|-----------|
| 2.4 | Implement caching | in_progress |
| 2.5 | Add rate limiting | todo |

Options:
1. Complete these tasks first, then run /close-epic again
2. Move incomplete tasks to a different epic
3. Remove tasks from scope (with justification)

What would you like to do?
```

### 3. Review Acceptance Criteria

Show the epic's acceptance criteria and ask for confirmation:

```markdown
## Acceptance Criteria Review

Epic 2: Core Features

Please verify each criterion is met:

- [ ] All API endpoints return proper error codes
- [ ] Response times under 200ms for 95th percentile
- [ ] Unit test coverage above 80%

Are all acceptance criteria met? (yes/no/need changes)
```

### 4. Update the Plan

Once verified, update `docs/development-plan.md`:

1. **Update epic header:**
   ```markdown
   ## Epic 2: Core Features (COMPLETE)
   ```

2. **Update Completion Status Summary:**
   ```markdown
   | 2. Core Features | Complete | 100% |
   ```

3. **Mark acceptance criteria as checked:**
   ```markdown
   ### Acceptance Criteria

   - [x] All API endpoints return proper error codes
   - [x] Response times under 200ms for 95th percentile
   - [x] Unit test coverage above 80%
   ```

4. **Update "Last synced" date**

5. **Add changelog entry:**
   ```markdown
   - **[date]**: Marked Epic 2: Core Features as COMPLETE (all 6 tasks done)
   ```

### 5. Provide Summary

Output a completion summary:

```markdown
## Epic Closed Successfully

**Epic:** 2. Core Features
**Status:** COMPLETE
**Tasks Completed:** 6/6
**Closed On:** [date]

### Completed Tasks
- [x] 2.1 Implement user API
- [x] 2.2 Implement auth
- [x] 2.3 Add validation
- [x] 2.4 Implement caching
- [x] 2.5 Add rate limiting
- [x] 2.6 Add logging

### Acceptance Criteria Met
- [x] All API endpoints return proper error codes
- [x] Response times under 200ms for 95th percentile
- [x] Unit test coverage above 80%

### Updated Progress

| Epic | Status | Progress |
|------|--------|----------|
| 1. Foundation | Complete | 100% |
| 2. Core Features | Complete | 100% |
| 3. Supporting | Not Started | 0% |

**Overall Progress:** 12/20 tasks (60%)

### Next Steps
- Start work on Epic 3: Supporting Features
- Consider running /sync-plan to verify all statuses
- Commit the updated development plan
```

## Handling Partial Completion

If the user wants to close an epic with incomplete tasks:

### Option A: Move Tasks
```markdown
Move incomplete tasks to another epic:

Tasks to move:
- 2.4 Implement caching
- 2.5 Add rate limiting

Move to which epic? (or create new epic)
```

Update task IDs accordingly (e.g., 2.4 → 3.7 if moving to Epic 3).

### Option B: Remove from Scope
```markdown
Remove tasks from scope:

Please provide justification for removing:
- 2.4 Implement caching
- 2.5 Add rate limiting

This will be documented in the changelog.
```

Add to changelog:
```markdown
- **[date]**: Closed Epic 2: Core Features; removed tasks 2.4, 2.5 from scope (deferred to future release)
```

### Option C: Mark as Partial
```markdown
Mark epic as partially complete:

## Epic 2: Core Features (PARTIAL - 4/6 tasks)

Note: Tasks 2.4 and 2.5 deferred.
```

## Notes

- Always verify with VibeKanban before closing - don't rely solely on the plan file
- Closing an epic is a significant milestone - document it well
- If acceptance criteria aren't defined, ask the user to confirm the epic is truly complete
- Consider if any documentation or cleanup tasks should be added before closing
