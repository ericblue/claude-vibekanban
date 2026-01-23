---
description: Show development plan progress summary without modifying files
allowed-tools: mcp__vibekanban__list_projects, mcp__vibekanban__list_tasks, mcp__vibekanban__get_task
---

# Plan Status

## Context

You are providing a quick progress overview of the development plan by checking VibeKanban task statuses. This is a **read-only** operation - it does not modify the plan file.

## Current Plan

!`cat docs/development-plan.md 2>/dev/null || echo "ERROR: No development plan found at docs/development-plan.md"`

## Instructions

### 1. Parse the Development Plan

Extract:
- All epics with their names
- All tasks with their VK task IDs
- Current status/progress shown in the plan

### 2. Fetch Current Status from VibeKanban

For each task with a VK ID:
- Use `get_task` to fetch current status
- Track: todo, in_progress, done

### 3. Calculate Progress

For each epic:
- Total tasks
- Completed tasks
- In-progress tasks
- Not started tasks
- Completion percentage

Overall:
- Total epics
- Epics complete
- Total tasks across all epics
- Overall completion percentage

### 4. Display Progress Report

Output a formatted progress report:

```markdown
# Development Plan Status

**Project:** [Project Name]
**VibeKanban Project:** [VK Project Name]
**Report Generated:** [timestamp]

## Overall Progress

```
[=========>          ] 45% Complete
```

- **Total Tasks:** 20
- **Completed:** 9
- **In Progress:** 3
- **Not Started:** 8

## Epic Progress

| Epic | Progress | Status | Tasks |
|------|----------|--------|-------|
| 1. Foundation | [==========] 100% | Complete | 4/4 |
| 2. Core Features | [=====>    ] 50% | In Progress | 3/6 |
| 3. Supporting | [          ] 0% | Not Started | 0/5 |
| 4. Polish | [=>        ] 10% | In Progress | 1/5 |

## Recently Completed
- [x] 1.1 Set up project structure
- [x] 1.2 Configure database
- [x] 2.1 Implement user API

## Currently In Progress
- [ ] 2.2 Implement auth (in_progress)
- [ ] 2.3 Add validation (in_progress)
- [ ] 4.1 Error handling (in_progress)

## Up Next (High Priority)
- [ ] 2.4 Implement caching (High)
- [ ] 2.5 Add rate limiting (High)
- [ ] 3.1 Email integration (High)

## Warnings

- 2 tasks in plan without VK IDs
- Plan "Last synced" is 3 days old - consider running /sync-plan
```

## Progress Bar Format

Use text-based progress bars:
- `[          ]` 0%
- `[=>        ]` 10%
- `[===>      ]` 30%
- `[=====>    ]` 50%
- `[=======>  ]` 70%
- `[=========>]` 90%
- `[==========]` 100%

## Comparison with Plan

If the VK status differs from what's shown in the plan, note it:

```markdown
## Out of Sync

The following tasks have different status in VK vs the plan:

| Task | Plan Shows | VK Shows |
|------|------------|----------|
| 2.2 Implement auth | Not Started | In Progress |
| 1.4 Add tests | In Progress | Complete |

Run `/sync-plan` to update the development plan.
```

## Quick Actions

At the end, suggest relevant actions:

```markdown
## Suggested Actions

- Run `/sync-plan` to update the plan with latest status
- Run `/generate-tasks` to link 2 untracked tasks to VK
- Consider starting Epic 3 - Epic 2 is 80% complete
```

## Notes

- This command is read-only and safe to run anytime
- For a full sync that updates the plan file, use `/sync-plan`
- Task counts exclude any tasks not linked to VibeKanban
