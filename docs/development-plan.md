# Development Plan: Claude VibeKanban

> **VibeKanban Project ID:** *(to be linked after task generation)*
> **PRD:** [docs/prd.md](./prd.md)
> **Last synced:** 2026-02-07

---

## Completion Status Summary

| Epic | Status | Progress |
|------|--------|----------|
| 1. Parallel Execution Stabilization | NOT STARTED | 0% |
| 2. Dependency Management Enhancements | NOT STARTED | 0% |
| 3. Completion Tracking & Observability | NOT STARTED | 0% |
| 4. Error Recovery & Resilience | NOT STARTED | 0% |
| 5. Developer Experience Improvements | NOT STARTED | 0% |
| 6. Documentation & Testing | NOT STARTED | 0% |

---

## Epic 1: Parallel Execution Stabilization (NOT STARTED)

**Goal:** Stabilize the experimental parallel execution features (Tier 1 local worktrees, Tier 2 remote delegation) for production use.

### Acceptance Criteria
- [ ] `/work-parallel` reliably creates worktrees and launches sessions
- [ ] `/merge-parallel` handles merge conflicts gracefully
- [ ] Tier 2 delegation fails gracefully when VK worktree manager errors
- [ ] Session status accurately reflects all active work

### Tasks

| ID | Title | Description | Priority | Complexity | Depends On | Status |
|----|-------|-------------|----------|------------|------------|--------|
| 1.1 | Add worktree pre-flight checks | Validate git state, branch names, and disk space before creating worktrees | High | M | — | <!-- vk: --> |
| 1.2 | Implement graceful Tier 2 fallback | Detect VK workspace session failures and suggest Tier 1 alternative | High | M | — | <!-- vk: --> |
| 1.3 | Add merge conflict detection | Detect conflicts before merge, report affected files, suggest resolution | High | L | — | <!-- vk: --> |
| 1.4 | Improve session status aggregation | Combine local worktree status with VK session status in unified view | Medium | M | 1.2 | <!-- vk: --> |
| 1.5 | Add session timeout handling | Detect stale sessions, offer cleanup or resume options | Medium | M | 1.4 | <!-- vk: --> |
| 1.6 | Document parallel execution best practices | Add cookbook section for parallel workflows with examples | Low | S | 1.1, 1.2, 1.3 | <!-- vk: --> |

### Task Details

**1.1 - Add worktree pre-flight checks**
- [ ] Check that current directory is a git repository
- [ ] Verify no uncommitted changes in main worktree
- [ ] Validate proposed branch names don't conflict
- [ ] Check available disk space meets minimum threshold
- [ ] Report all issues before creating any worktrees

**1.2 - Implement graceful Tier 2 fallback**
- [ ] Detect `fatal: invalid reference` errors from VK
- [ ] Catch workspace session creation failures
- [ ] Present clear error message explaining the issue
- [ ] Suggest `/work-parallel` (Tier 1) as fallback option
- [ ] Log failure details for VK team debugging

**1.3 - Add merge conflict detection**
- [ ] Perform dry-run merge before actual merge
- [ ] List conflicting files if conflicts detected
- [ ] Offer options: abort, manual resolution, skip branch
- [ ] Continue with remaining branches after skip
- [ ] Update VK task status appropriately for skipped tasks

**1.4 - Improve session status aggregation**
- [ ] Query local git worktrees for status
- [ ] Query VK API for active workspace sessions
- [ ] Combine into unified status table
- [ ] Show task ID, branch, location, last activity
- [ ] Indicate which sessions are local vs remote

**1.5 - Add session timeout handling**
- [ ] Define stale session threshold (configurable, default 4 hours)
- [ ] Detect sessions with no recent activity
- [ ] Offer cleanup (delete worktree/cancel session) or resume
- [ ] Update VK task status when cleaning up stale sessions
- [ ] Log timeout events for debugging

**1.6 - Document parallel execution best practices**
- [ ] Add cookbook section for Tier 1 workflow
- [ ] Add cookbook section for Tier 2 workflow
- [ ] Include troubleshooting for common failures
- [ ] Provide examples for 2-3 task parallel execution
- [ ] Document when to use Tier 1 vs Tier 2

---

## Epic 2: Dependency Management Enhancements (NOT STARTED)

**Goal:** Strengthen dependency validation to prevent violations and detect problematic patterns.

### Acceptance Criteria
- [ ] Circular dependencies detected before execution
- [ ] Optional strict mode blocks work on tasks with unmet dependencies
- [ ] Dependency violations clearly reported during sync

### Tasks

| ID | Title | Description | Priority | Complexity | Depends On | Status |
|----|-------|-------------|----------|------------|------------|--------|
| 2.1 | Implement cycle detection algorithm | Detect circular dependencies in plan and report affected tasks | High | M | — | <!-- vk: --> |
| 2.2 | Add strict dependency enforcement mode | Optional mode that blocks execution of tasks with unmet dependencies | High | M | 2.1 | <!-- vk: --> |
| 2.3 | Enhance sync drift detection for dependencies | Report when in-progress/done tasks have incomplete dependencies | Medium | S | — | <!-- vk: --> |
| 2.4 | Add dependency visualization | Generate text-based dependency graph for plan overview | Low | M | 2.1 | <!-- vk: --> |

### Task Details

**2.1 - Implement cycle detection algorithm**
- [ ] Parse all task dependencies from plan
- [ ] Build directed graph of task relationships
- [ ] Implement cycle detection (DFS with back-edge detection)
- [ ] Report all cycles found with affected task IDs
- [ ] Integrate check into `/create-plan` and `/sync-plan`

**2.2 - Add strict dependency enforcement mode**
- [ ] Add `strict_dependencies: true` option to plan metadata
- [ ] Check all dependencies are `done` before allowing task start
- [ ] Block `/work-task` and `/work-next` for violating tasks
- [ ] Provide clear message explaining which dependencies are blocking
- [ ] Allow override with explicit user confirmation

**2.3 - Enhance sync drift detection for dependencies**
- [ ] During sync, check each non-todo task's dependencies
- [ ] Flag tasks started/completed before dependencies done
- [ ] Add "Dependency Violations" section to sync report
- [ ] Suggest corrective actions (revert status, mark deps done)

**2.4 - Add dependency visualization**
- [ ] Generate ASCII/text dependency graph
- [ ] Show task IDs with status indicators
- [ ] Highlight blocked tasks and available tasks
- [ ] Include in `/plan-status` output (optional flag)

---

## Epic 3: Completion Tracking & Observability (NOT STARTED)

**Goal:** Improve visibility into what agents did during task execution for debugging and review.

### Acceptance Criteria
- [ ] All completed tasks have structured completion logs
- [ ] Merge logs appended for parallel merged tasks
- [ ] Session activity can be reviewed after completion

### Tasks

| ID | Title | Description | Priority | Complexity | Depends On | Status |
|----|-------|-------------|----------|------------|------------|--------|
| 3.1 | Standardize completion log format | Define and document structured format for completion logs | High | S | — | <!-- vk: --> |
| 3.2 | Add merge log to completion tracking | Record merge results, conflicts resolved, tests run in task description | High | S | 3.1 | <!-- vk: --> |
| 3.3 | Implement session recording for Tier 1 | Optionally record agent session transcripts for post-mortem | Medium | L | — | <!-- vk: --> |
| 3.4 | Add VK activity log integration | When VK supports activity log API, use it instead of description appending | Low | M | — | <!-- vk: --> |

### Task Details

**3.1 - Standardize completion log format**
- [ ] Define schema: agent, branch, changes, summary, AC checklist
- [ ] Document format in architecture.md
- [ ] Update all execution commands to use consistent format
- [ ] Add timestamp to completion logs
- [ ] Include commit hashes for key changes

**3.2 - Add merge log to completion tracking**
- [ ] Record branch merged and commit hash
- [ ] Note any conflicts that were resolved
- [ ] Record test results (pass/fail with summary)
- [ ] Append to task description via update_task
- [ ] Format consistently with completion log structure

**3.3 - Implement session recording for Tier 1**
- [ ] Add optional `--record` flag to `/work-parallel`
- [ ] Capture stdout/stderr from screen/tmux sessions
- [ ] Store in `../project-worktrees/task-<id>.log`
- [ ] Include session log path in completion log
- [ ] Add playback/review instructions to cookbook

**3.4 - Add VK activity log integration**
- [ ] Check for VK activity log API availability
- [ ] If available, use proper log endpoint instead of description
- [ ] Fall back to description appending if not available
- [ ] Document API requirements for VK team

---

## Epic 4: Error Recovery & Resilience (NOT STARTED)

**Goal:** Handle failures gracefully and help users recover from error states.

### Acceptance Criteria
- [ ] Clear error messages with actionable recovery steps
- [ ] Failed tasks can be retried or reassigned
- [ ] Partial failures don't corrupt plan state

### Tasks

| ID | Title | Description | Priority | Complexity | Depends On | Status |
|----|-------|-------------|----------|------------|------------|--------|
| 4.1 | Add task retry mechanism | Allow retrying failed tasks with fresh context | High | M | — | <!-- vk: --> |
| 4.2 | Implement plan backup before modifications | Create backup before plan edits to enable recovery | High | S | — | <!-- vk: --> |
| 4.3 | Add partial failure handling for parallel execution | When some tasks succeed and some fail, update appropriately | Medium | M | 1.3 | <!-- vk: --> |
| 4.4 | Improve MCP error messages | Parse VK MCP errors and provide user-friendly explanations | Medium | S | — | <!-- vk: --> |

### Task Details

**4.1 - Add task retry mechanism**
- [ ] Add `/retry-task` command or retry option in `/work-task`
- [ ] Reset task status to `todo` in VK
- [ ] Clear previous completion log if present
- [ ] Re-assemble context and restart execution
- [ ] Track retry count in task description

**4.2 - Implement plan backup before modifications**
- [ ] Before any plan edit, copy to `development-plan.md.bak`
- [ ] Keep only most recent backup (not versioned history)
- [ ] Add restore command or instructions
- [ ] Skip backup for read-only operations

**4.3 - Add partial failure handling for parallel execution**
- [ ] Track success/failure for each parallel task
- [ ] Update successful tasks to appropriate status
- [ ] Keep failed tasks in `inprogress` with failure note
- [ ] Report summary: N succeeded, M failed
- [ ] Suggest next steps for failed tasks

**4.4 - Improve MCP error messages**
- [ ] Catch common VK error patterns
- [ ] Map to user-friendly explanations
- [ ] Suggest fixes: check VK connection, verify project ID, etc.
- [ ] Log raw error for debugging if needed

---

## Epic 5: Developer Experience Improvements (NOT STARTED)

**Goal:** Make the workflow smoother and reduce friction in common operations.

### Acceptance Criteria
- [ ] Common workflows require fewer manual steps
- [ ] Better feedback during long-running operations
- [ ] Consistent experience across all commands

### Tasks

| ID | Title | Description | Priority | Complexity | Depends On | Status |
|----|-------|-------------|----------|------------|------------|--------|
| 5.1 | Add progress indicators for long operations | Show progress during task generation, sync, parallel launch | Medium | S | — | <!-- vk: --> |
| 5.2 | Implement quick-start wizard | Guided setup for new projects: PRD → Plan → Tasks in one flow | Medium | L | — | <!-- vk: --> |
| 5.3 | Add plan validation command | Check plan for issues: missing AC, invalid dependencies, format errors | Medium | M | 2.1 | <!-- vk: --> |
| 5.4 | Improve task search in work-task | Better fuzzy matching for task titles and IDs | Low | S | — | <!-- vk: --> |
| 5.5 | Add command shortcuts | Allow abbreviated commands: `/wn` for `/work-next`, `/ps` for `/plan-status` | Low | S | — | <!-- vk: --> |

### Task Details

**5.1 - Add progress indicators for long operations**
- [ ] Show count/total during task generation (e.g., "Creating task 5/12")
- [ ] Show sync progress (e.g., "Checking task 8/20")
- [ ] Show parallel launch progress (e.g., "Starting session 2/3")
- [ ] Use consistent format across commands

**5.2 - Implement quick-start wizard**
- [ ] Single command to run full workflow
- [ ] Interactive prompts for project idea
- [ ] Generate PRD with user confirmation
- [ ] Create plan with user confirmation
- [ ] Generate VK tasks with user confirmation
- [ ] Link tasks and show summary

**5.3 - Add plan validation command**
- [ ] Check all tasks have acceptance criteria
- [ ] Validate dependency references exist
- [ ] Check for circular dependencies (use 2.1)
- [ ] Verify VK ID format is correct
- [ ] Report all issues with line numbers

**5.4 - Improve task search in work-task**
- [ ] Support partial ID matching (e.g., "2.3" matches "2.3")
- [ ] Support fuzzy title matching
- [ ] Show multiple matches if ambiguous
- [ ] Let user select from matches

**5.5 - Add command shortcuts**
- [ ] Create alias commands: `wn.md`, `ps.md`, `wt.md`, etc.
- [ ] Document shortcuts in workflow command
- [ ] Update install.sh to include shortcuts
- [ ] Keep full commands as canonical

---

## Epic 6: Documentation & Testing (NOT STARTED)

**Goal:** Ensure comprehensive documentation and validate workflow through testing.

### Acceptance Criteria
- [ ] All commands have up-to-date documentation
- [ ] Cookbook covers common scenarios and troubleshooting
- [ ] End-to-end workflow validated through dogfooding

### Tasks

| ID | Title | Description | Priority | Complexity | Depends On | Status |
|----|-------|-------------|----------|------------|------------|--------|
| 6.1 | Update architecture.md for new features | Document parallel execution model, completion tracking updates | High | M | 1.6, 3.1 | <!-- vk: --> |
| 6.2 | Expand cookbook with troubleshooting | Add FAQ section, common error solutions, workflow tips | Medium | M | — | <!-- vk: --> |
| 6.3 | Add command reference to README | Sync README command table with current feature set | Medium | S | — | <!-- vk: --> |
| 6.4 | Validate workflow through dogfooding | Use this plan to develop features, track issues, refine commands | High | XL | — | <!-- vk: --> |
| 6.5 | Create release checklist | Document release process: version bump, testing, changelog | Low | S | — | <!-- vk: --> |

### Task Details

**6.1 - Update architecture.md for new features**
- [ ] Document Tier 1/Tier 2 parallel execution in detail
- [ ] Add completion log format specification
- [ ] Update limitations section with current known issues
- [ ] Add new diagrams if helpful

**6.2 - Expand cookbook with troubleshooting**
- [ ] Add FAQ section with common questions
- [ ] Document error recovery procedures
- [ ] Add workflow tips and best practices
- [ ] Include real examples from dogfooding

**6.3 - Add command reference to README**
- [ ] Ensure all 17 commands listed with descriptions
- [ ] Mark experimental commands appropriately
- [ ] Keep version numbers in sync
- [ ] Link to detailed docs for complex commands

**6.4 - Validate workflow through dogfooding**
- [ ] Use this development plan for claude-vibekanban development
- [ ] Track issues encountered during execution
- [ ] Refine commands based on real usage
- [ ] Document improvements made

**6.5 - Create release checklist**
- [ ] Document `make release` workflow
- [ ] Include testing steps before release
- [ ] Define changelog format
- [ ] Add tag and push instructions

---

## Dependency Graph

```
Epic 1: Parallel Execution Stabilization
  1.1 ──┬──→ 1.6
  1.2 ──┤     ↑
  1.3 ──┴──→ 1.6
       ↓
  1.4 ──→ 1.5

Epic 2: Dependency Management
  2.1 ──→ 2.2
   │
   └──→ 2.4

  2.3 (independent)

Epic 3: Completion Tracking
  3.1 ──→ 3.2
  3.3 (independent)
  3.4 (independent, blocked on VK API)

Epic 4: Error Recovery
  4.1 (independent)
  4.2 (independent)
  4.3 ←── 1.3 (cross-epic)
  4.4 (independent)

Epic 5: Developer Experience
  5.1 (independent)
  5.2 (independent)
  5.3 ←── 2.1 (cross-epic)
  5.4 (independent)
  5.5 (independent)

Epic 6: Documentation
  6.1 ←── 1.6, 3.1 (cross-epic)
  6.2 (independent)
  6.3 (independent)
  6.4 (independent, ongoing)
  6.5 (independent)
```

---

## Changelog

| Date | Action | Details |
|------|--------|---------|
| 2026-02-07 | Plan created | Initial development plan with 6 epics, 25 tasks |

---

*This development plan was generated as part of dogfooding the claude-vibekanban workflow.*
