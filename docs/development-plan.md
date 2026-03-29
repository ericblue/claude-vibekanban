# Development Plan: Claude VibeKanban

> **VibeKanban Project ID:** `1029435c-9a74-4472-83df-693b621df265`
> **PRD:** [docs/prd.md](./prd.md)
> **Last synced:** 2026-02-28

---

## Epic Shorthand Key

| Shorthand | Epic |
|-----------|------|
| PAR | Parallel Execution Stabilization |
| DEP | Dependency Management |
| TRK | Completion Tracking & Observability |
| REC | Error Recovery & Resilience |
| DX | Developer Experience |
| DOC | Documentation & Testing |
| ORC | Agent Roles & Orchestrator |
| ADAPT | Kanban Adapter |

---

## Completion Status Summary

| Epic | Status | Progress | Priority |
|------|--------|----------|----------|
| **7 [ORC] Agent Roles & Orchestrator** | **NOT STARTED** | **0/13 (0%)** | **HIGHEST** |
| 1 [PAR] Parallel Execution Stabilization | IN PROGRESS | 1/12 (8%) | High |
| 2 [DEP] Dependency Management | NOT STARTED | 0/4 (0%) | High |
| 3 [TRK] Completion Tracking & Observability | NOT STARTED | 0/8 (0%) | Medium |
| 4 [REC] Error Recovery & Resilience | NOT STARTED | 0/4 (0%) | Medium |
| 5 [DX] Developer Experience | NOT STARTED | 0/8 (0%) | Medium |
| 6 [DOC] Documentation & Testing | IN PROGRESS | 5/12 (42%) | Low |
| 8 [ADAPT] Kanban Adapter | NOT STARTED | 0/1 (0%) | Medium |
| **Total** | | **6/62 (10%)** | |

---

## Epic 1: Parallel Execution Stabilization — [PAR] (IN PROGRESS)

**Goal:** Stabilize the experimental parallel execution features (Tier 1 local worktrees, Tier 2 remote delegation) for production use.

### Acceptance Criteria
- [ ] `/work-parallel` reliably creates worktrees and launches sessions
- [ ] `/merge-parallel` handles merge conflicts gracefully
- [ ] Tier 2 delegation fails gracefully when VK worktree manager errors
- [ ] Session status accurately reflects all active work

### Tasks

| ID | Title | Priority | Complexity | Depends On | Status | VK |
|----|-------|----------|------------|------------|--------|----|
| 1.1 [PAR] | Add worktree pre-flight checks | High | M | — | To do | ERI-31 |
| 1.2 [PAR] | Implement graceful Tier 2 fallback | High | M | — | To do | ERI-12, ERI-13 |
| 1.3 [PAR] | Add merge conflict detection | High | L | — | To do | ERI-21 |
| 1.4 [PAR] | Improve session status aggregation | Medium | M | 1.2 | To do | ERI-16 |
| 1.5 [PAR] | Add session timeout handling | Medium | M | 1.4 | To do | ERI-32 |
| 1.6 [PAR] | Document parallel execution best practices | Low | S | 1.1, 1.2, 1.3 | **Done** | ERI-33 |
| 1.7 [PAR] | Fix screen sessions showing blank output when attached | High | M | — | To do | ERI-15 |
| 1.8 [PAR] | Add /review-parallel command to verify worktrees before merge | Medium | M | — | To do | ERI-20 |
| 1.9 [PAR] | Fix screen session quoting for prompts with backticks and $() | High | S | — | To do | ERI-22 |
| 1.10 [PAR] | Fix parallel agents writing to main repo instead of worktrees | High | M | — | To do | ERI-23 |
| 1.11 [PAR] | Fix screen -Logfile flag on macOS | Medium | S | — | To do | ERI-24 |
| 1.12 [PAR] | /work-parallel must always prompt for permission mode | High | S | — | To do | ERI-25 |

### Task Details

**1.1 [PAR] — Add worktree pre-flight checks** *(ERI-31)*
- [ ] Check that current directory is a git repository
- [ ] Verify no uncommitted changes in main worktree
- [ ] Validate proposed branch names don't conflict
- [ ] Check available disk space meets minimum threshold
- [ ] Report all issues before creating any worktrees

**1.2 [PAR] — Implement graceful Tier 2 fallback** *(ERI-12, ERI-13)*
- [ ] Detect `fatal: invalid reference` errors from VK
- [ ] Catch workspace session creation failures
- [ ] Present clear error message explaining the issue
- [ ] Suggest `/work-parallel` (Tier 1) as fallback option
- [ ] Add Tier 2 worktree failure warning to /delegate-task and /delegate-parallel
- [ ] Log failure details for VK team debugging

**1.3 [PAR] — Add merge conflict detection** *(ERI-21)*
- [ ] Perform dry-run merge before actual merge
- [ ] List conflicting files if conflicts detected
- [ ] Offer options: abort, manual resolution, skip branch
- [ ] Auto-detect tests and run final integration pass
- [ ] Continue with remaining branches after skip
- [ ] Update VK task status appropriately for skipped tasks

**1.4 [PAR] — Improve session status aggregation** *(ERI-16)*
- [ ] Query local git worktrees for status
- [ ] Query VK API for active workspace sessions
- [ ] Combine into unified status table
- [ ] Show task ID, branch, location, last activity
- [ ] Indicate which sessions are local vs remote
- [ ] Support lightweight /quick-status command for monitoring

**1.5 [PAR] — Add session timeout handling** *(ERI-32)*
- [ ] Define stale session threshold (configurable, default 4 hours)
- [ ] Detect sessions with no recent activity
- [ ] Offer cleanup (delete worktree/cancel session) or resume
- [ ] Update VK task status when cleaning up stale sessions
- [ ] Log timeout events for debugging

**1.6 [PAR] — Document parallel execution best practices** *(ERI-33)* — **DONE**
- [x] Add cookbook section for Tier 1 workflow
- [x] Add cookbook section for Tier 2 workflow
- [x] Include troubleshooting for common failures
- [x] Provide examples for 2-3 task parallel execution
- [x] Document when to use Tier 1 vs Tier 2

**1.7 [PAR] — Fix screen sessions showing blank output** *(ERI-15)*
- [ ] Diagnose why screen sessions show blank when attached
- [ ] Fix output capture/display issue
- [ ] Verify fix works on macOS

**1.9 [PAR] — Fix screen session quoting** *(ERI-22)*
- [ ] Test prompts with backticks and $() in screen sessions
- [ ] Fix quoting/escaping to prevent expansion
- [ ] Verify fix across bash and zsh

**1.10 [PAR] — Fix parallel agents writing to main repo** *(ERI-23)*
- [ ] Identify root cause of agents targeting main repo instead of worktree
- [ ] Ensure working directory is correctly set for each session
- [ ] Verify isolation between parallel worktrees

---

## Epic 2: Dependency Management Enhancements — [DEP] (NOT STARTED)

**Goal:** Strengthen dependency validation to prevent violations and detect problematic patterns.

### Acceptance Criteria
- [ ] Circular dependencies detected before execution
- [ ] Optional strict mode blocks work on tasks with unmet dependencies
- [ ] Dependency violations clearly reported during sync

### Tasks

| ID | Title | Priority | Complexity | Depends On | Status | VK |
|----|-------|----------|------------|------------|--------|----|
| 2.1 [DEP] | Implement cycle detection algorithm | High | M | — | To do | ERI-34 |
| 2.2 [DEP] | Add strict dependency enforcement mode | High | M | 2.1 | To do | ERI-35 |
| 2.3 [DEP] | Enhance sync drift detection for dependencies | Medium | S | — | To do | ERI-36 |
| 2.4 [DEP] | Add dependency visualization | Low | M | 2.1 | To do | ERI-37 |

### Task Details

**2.1 [DEP] — Implement cycle detection algorithm** *(ERI-34)*
- [ ] Parse all task dependencies from plan
- [ ] Build directed graph of task relationships
- [ ] Implement cycle detection (DFS with back-edge detection)
- [ ] Report all cycles found with affected task IDs
- [ ] Integrate check into `/create-plan` and `/sync-plan`

**2.2 [DEP] — Add strict dependency enforcement mode** *(ERI-35)*
- [ ] Add `strict_dependencies: true` option to plan metadata
- [ ] Check all dependencies are `done` before allowing task start
- [ ] Block `/work-task` and `/work-next` for violating tasks
- [ ] Provide clear message explaining which dependencies are blocking
- [ ] Allow override with explicit user confirmation

**2.3 [DEP] — Enhance sync drift detection for dependencies** *(ERI-36)*
- [ ] During sync, check each non-todo task's dependencies
- [ ] Flag tasks started/completed before dependencies done
- [ ] Add "Dependency Violations" section to sync report
- [ ] Suggest corrective actions (revert status, mark deps done)

**2.4 [DEP] — Add dependency visualization** *(ERI-37)*
- [ ] Generate ASCII/text dependency graph
- [ ] Show task IDs with status indicators
- [ ] Highlight blocked tasks and available tasks
- [ ] Include in `/plan-status` output (optional flag)

---

## Epic 3: Completion Tracking & Observability — [TRK] (NOT STARTED)

**Goal:** Improve visibility into what agents did during task execution for debugging and review.

### Acceptance Criteria
- [ ] All completed tasks have structured completion logs
- [ ] Merge logs appended for parallel merged tasks
- [ ] Session activity can be reviewed after completion

### Tasks

| ID | Title | Priority | Complexity | Depends On | Status | VK |
|----|-------|----------|------------|------------|--------|----|
| 3.1 [TRK] | Standardize completion log format | High | S | — | To do | ERI-38 |
| 3.2 [TRK] | Add merge log to completion tracking | High | S | 3.1 | To do | ERI-39 |
| 3.3 [TRK] | Implement session recording for Tier 1 | Medium | L | — | To do | ERI-40 |
| 3.4 [TRK] | Add VK activity log integration | Low | M | — | To do | ERI-41 |
| 3.5 [TRK] | /work-next missing completion log instructions | High | S | — | To do | ERI-2 |
| 3.6 [TRK] | /work-task skips completion log update to VK ticket | High | S | — | To do | ERI-19 |
| 3.7 [TRK] | Add elapsed time to completion logs for estimate calibration | Medium | S | 3.1 | To do | ERI-14 |
| 3.8 [TRK] | Preserve agent work logs and prompts with configurable output | Medium | M | — | To do | ERI-26 |

### Task Details

**3.1 [TRK] — Standardize completion log format** *(ERI-38)*
- [ ] Define schema: agent, branch, changes, summary, AC checklist
- [ ] Document format in architecture.md
- [ ] Update all execution commands to use consistent format
- [ ] Add timestamp to completion logs
- [ ] Include commit hashes for key changes

**3.2 [TRK] — Add merge log to completion tracking** *(ERI-39)*
- [ ] Record branch merged and commit hash
- [ ] Note any conflicts that were resolved
- [ ] Record test results (pass/fail with summary)
- [ ] Append to task description via update_task
- [ ] Format consistently with completion log structure

**3.3 [TRK] — Implement session recording for Tier 1** *(ERI-40)*
- [ ] Add optional `--record` flag to `/work-parallel`
- [ ] Capture stdout/stderr from screen/tmux sessions
- [ ] Store in `../project-worktrees/task-<id>.log`
- [ ] Include session log path in completion log
- [ ] Add playback/review instructions to cookbook

**3.4 [TRK] — Add VK activity log integration** *(ERI-41)*
- [ ] Check for VK activity log API availability
- [ ] If available, use proper log endpoint instead of description
- [ ] Fall back to description appending if not available
- [ ] Document API requirements for VK team

**3.5 [TRK] — /work-next missing completion log instructions** *(ERI-2)*
- [ ] Add completion log update step to /work-next command
- [ ] Ensure parity with /work-task completion behavior

**3.6 [TRK] — /work-task skips completion log update to VK ticket** *(ERI-19)*
- [ ] Identify where completion log update is being skipped
- [ ] Fix to always update VK ticket on task completion

**3.8 [TRK] — Preserve agent work logs and prompts with configurable output** *(ERI-26)*
- [ ] Design configurable output destinations for agent logs
- [ ] Capture full prompts sent to agents during execution
- [ ] Store logs in project-local or user-configurable location

---

## Epic 4: Error Recovery & Resilience — [REC] (NOT STARTED)

**Goal:** Handle failures gracefully and help users recover from error states.

### Acceptance Criteria
- [ ] Clear error messages with actionable recovery steps
- [ ] Failed tasks can be retried or reassigned
- [ ] Partial failures don't corrupt plan state

### Tasks

| ID | Title | Priority | Complexity | Depends On | Status | VK |
|----|-------|----------|------------|------------|--------|----|
| 4.1 [REC] | Add task retry mechanism | High | M | — | To do | ERI-42 |
| 4.2 [REC] | Implement plan backup before modifications | High | S | — | To do | ERI-43 |
| 4.3 [REC] | Add partial failure handling for parallel execution | Medium | M | 1.3 | To do | ERI-44 |
| 4.4 [REC] | Improve MCP error messages | Medium | S | — | To do | ERI-45 |

### Task Details

**4.1 [REC] — Add task retry mechanism** *(ERI-42)*
- [ ] Add `/retry-task` command or retry option in `/work-task`
- [ ] Reset task status to `todo` in VK
- [ ] Clear previous completion log if present
- [ ] Re-assemble context and restart execution
- [ ] Track retry count in task description

**4.2 [REC] — Implement plan backup before modifications** *(ERI-43)*
- [ ] Before any plan edit, copy to `development-plan.md.bak`
- [ ] Keep only most recent backup (not versioned history)
- [ ] Add restore command or instructions
- [ ] Skip backup for read-only operations

**4.3 [REC] — Add partial failure handling for parallel execution** *(ERI-44)*
- [ ] Track success/failure for each parallel task
- [ ] Update successful tasks to appropriate status
- [ ] Keep failed tasks in `inprogress` with failure note
- [ ] Report summary: N succeeded, M failed
- [ ] Suggest next steps for failed tasks

**4.4 [REC] — Improve MCP error messages** *(ERI-45)*
- [ ] Catch common VK error patterns
- [ ] Map to user-friendly explanations
- [ ] Suggest fixes: check VK connection, verify project ID, etc.
- [ ] Log raw error for debugging if needed

---

## Epic 5: Developer Experience Improvements — [DX] (NOT STARTED)

**Goal:** Make the workflow smoother and reduce friction in common operations.

### Acceptance Criteria
- [ ] Common workflows require fewer manual steps
- [ ] Better feedback during long-running operations
- [ ] Consistent experience across all commands

### Tasks

| ID | Title | Priority | Complexity | Depends On | Status | VK |
|----|-------|----------|------------|------------|--------|----|
| 5.1 [DX] | Add progress indicators for long operations | Medium | S | — | To do | ERI-46 |
| 5.2 [DX] | Implement quick-start wizard | Medium | L | — | To do | ERI-47 |
| 5.3 [DX] | Add plan validation command | Medium | M | 2.1 | To do | ERI-48 |
| 5.4 [DX] | Improve task search in work-task | Low | S | — | To do | ERI-49 |
| 5.5 [DX] | Add command shortcuts | Low | S | — | To do | ERI-50 |
| 5.6 [DX] | Fix command count mismatch in /workflow | High | S | — | To do | ERI-1 |
| 5.7 [DX] | Inconsistent AC verification format between /work-task and /work-next | Medium | S | — | To do | ERI-3 |
| 5.8 [DX] | Standardize "no plan file" error messages across commands | Medium | S | — | To do | ERI-10 |

### Task Details

**5.1 [DX] — Add progress indicators for long operations** *(ERI-46)*
- [ ] Show count/total during task generation (e.g., "Creating task 5/12")
- [ ] Show sync progress (e.g., "Checking task 8/20")
- [ ] Show parallel launch progress (e.g., "Starting session 2/3")
- [ ] Use consistent format across commands

**5.2 [DX] — Implement quick-start wizard** *(ERI-47)*
- [ ] Single command to run full workflow
- [ ] Interactive prompts for project idea
- [ ] Generate PRD with user confirmation
- [ ] Create plan with user confirmation
- [ ] Generate VK tasks with user confirmation
- [ ] Link tasks and show summary

**5.3 [DX] — Add plan validation command** *(ERI-48)*
- [ ] Check all tasks have acceptance criteria
- [ ] Validate dependency references exist
- [ ] Check for circular dependencies (use 2.1)
- [ ] Verify VK ID format is correct
- [ ] Report all issues with line numbers

**5.4 [DX] — Improve task search in work-task** *(ERI-49)*
- [ ] Support partial ID matching (e.g., "2.3" matches "2.3")
- [ ] Support fuzzy title matching
- [ ] Show multiple matches if ambiguous
- [ ] Let user select from matches

**5.5 [DX] — Add command shortcuts** *(ERI-50)*
- [ ] Create alias commands: `wn.md`, `ps.md`, `wt.md`, etc.
- [ ] Document shortcuts in workflow command
- [ ] Update install.sh to include shortcuts
- [ ] Keep full commands as canonical

**5.6 [DX] — Fix command count mismatch in /workflow** *(ERI-1)*
- [ ] Audit actual command count vs what /workflow reports
- [ ] Update /workflow output to match reality

**5.7 [DX] — Inconsistent AC verification format** *(ERI-3)*
- [ ] Compare AC verification output in /work-task vs /work-next
- [ ] Standardize to a single format across both commands

**5.8 [DX] — Standardize "no plan file" error messages** *(ERI-10)*
- [ ] Audit all commands for plan file missing handling
- [ ] Create consistent error message and suggestion
- [ ] Apply across all plan-dependent commands

---

## Epic 6: Documentation & Testing — [DOC] (IN PROGRESS)

**Goal:** Ensure comprehensive documentation and validate workflow through testing.

### Acceptance Criteria
- [ ] All commands have up-to-date documentation
- [x] Cookbook covers common scenarios and troubleshooting
- [ ] End-to-end workflow validated through dogfooding

### Tasks

| ID | Title | Priority | Complexity | Depends On | Status | VK |
|----|-------|----------|------------|------------|--------|----|
| 6.1 [DOC] | Update architecture.md for new features | High | M | 1.6, 3.1 | To do | ERI-51 |
| 6.2 [DOC] | Expand cookbook with troubleshooting | Medium | M | — | **Done** | ERI-52 |
| 6.3 [DOC] | Add command reference to README | Medium | S | — | **Done** | ERI-53 |
| 6.4 [DOC] | Validate workflow through dogfooding | High | XL | — | To do | ERI-54 |
| 6.5 [DOC] | Create release checklist | Low | S | — | To do | ERI-55 |
| 6.6 [DOC] | Add "Choosing an Execution Tier" decision matrix to cookbook | Medium | S | — | To do | ERI-4 |
| 6.7 [DOC] | Add session failure recovery guide to cookbook | Medium | S | — | To do | ERI-5 |
| 6.8 [DOC] | Add "Reopen a completed task" FAQ entry | Low | S | — | To do | ERI-6 |
| 6.9 [DOC] | Add conflict resolution guide for parallel merge | Medium | S | — | **Done** | ERI-7 |
| 6.10 [DOC] | Add plan scaling guidance to /create-plan and /add-epic | Low | S | — | To do | ERI-8 |
| 6.11 [DOC] | Add renamed commands section to README changelog | Low | S | — | **Done** | ERI-9 |
| 6.12 [DOC] | Create /generate-prd and /create-plan for this project (dogfood) | High | M | — | **Done** | ERI-11 |

### Task Details

**6.1 [DOC] — Update architecture.md for new features** *(ERI-51)*
- [ ] Document Tier 1/Tier 2 parallel execution in detail
- [ ] Add completion log format specification
- [ ] Update limitations section with current known issues
- [ ] Add new diagrams if helpful

**6.2 [DOC] — Expand cookbook with troubleshooting** *(ERI-52)* — **DONE**
- [x] Add FAQ section with common questions
- [x] Document error recovery procedures
- [x] Add workflow tips and best practices
- [x] Include real examples from dogfooding

**6.3 [DOC] — Add command reference to README** *(ERI-53)* — **DONE**
- [x] Ensure all 17 commands listed with descriptions
- [x] Mark experimental commands appropriately
- [x] Keep version numbers in sync
- [x] Link to detailed docs for complex commands

**6.4 [DOC] — Validate workflow through dogfooding** *(ERI-54)*
- [ ] Use this development plan for claude-vibekanban development
- [ ] Track issues encountered during execution
- [ ] Refine commands based on real usage
- [ ] Document improvements made

**6.5 [DOC] — Create release checklist** *(ERI-55)*
- [ ] Document `make release` workflow
- [ ] Include testing steps before release
- [ ] Define changelog format
- [ ] Add tag and push instructions

**6.9 [DOC] — Add conflict resolution guide for parallel merge** *(ERI-7)* — **DONE**
- [x] Cookbook FAQ: "Why doesn't `/merge-parallel` auto-resolve conflicts?"
- [x] Cookbook FAQ: "Can parallel tasks cause merge conflicts?"
- [x] Troubleshooting: "Merge conflicts after parallel work"
- [x] Troubleshooting: "`/merge-parallel` stops at conflicts"

**6.11 [DOC] — Add renamed commands section to README changelog** *(ERI-9)* — **DONE**
- [x] Documented `/delegate-batch` → `/delegate-parallel` rename in version history

**6.12 [DOC] — Create /generate-prd and /create-plan for this project** *(ERI-11)* — **DONE**
- [x] Generated PRD via /generate-prd
- [x] Created development plan via /create-plan

---

## Epic 7: Agent Roles & Autonomous Orchestrator — [ORC] (NOT STARTED) — HIGHEST PRIORITY

**Goal:** Replace the human-in-the-loop with a configurable autonomous orchestrator that coordinates specialized agent roles (PM, Architect, Tester, Developer) to drive the full planning-to-delivery lifecycle.

### Acceptance Criteria
- [ ] Agent roles (PM, Architect, Tester, Developer) each have dedicated system prompts shaping their behavior
- [ ] Roles can invoke existing slash commands (e.g., Tester runs tests, PM drives planning)
- [ ] Orchestrator can autonomously execute a full cycle: plan → prioritize → assign → execute → test → merge
- [ ] Configurable autonomy levels (fully autonomous, approval gates, review-only)
- [ ] Human can intervene, override, or pause at any point
- [ ] Orchestrator decisions and rationale are logged for review

### Tasks

| ID | Title | Priority | Complexity | Depends On | Status | VK |
|----|-------|----------|------------|------------|--------|----|
| 7.1 [ORC] | Design agent role architecture | High | L | — | To do | ERI-56 |
| 7.2 [ORC] | Create agent role prompt templates | High | L | 7.1 | To do | ERI-57 |
| 7.3 [ORC] | Build orchestrator engine | High | XL | 7.1, 7.2 | To do | ERI-58 |
| 7.4 [ORC] | Add orchestrator configuration system | High | M | 7.3 | To do | ERI-59 |
| 7.5 [ORC] | Integrate orchestrator with existing commands | High | L | 7.3 | To do | ERI-60 |
| 7.6 [ORC] | Add orchestrator observability & controls | High | M | 7.3, 7.4 | To do | ERI-61 |
| 7.7 [ORC] | Implement role-based task routing | Medium | L | 7.2, 7.3 | To do | ERI-62 |
| 7.8 [ORC] | Add autonomous testing & validation loop | Medium | L | 7.5, 7.7 | To do | ERI-63 |
| 7.9 [ORC] | Research Claude Code Agent Swarm | Medium | S | — | To do | ERI-17 |
| 7.10 [ORC] | Research parruda/swarm framework | Medium | S | — | To do | ERI-18 |
| 7.11 [ORC] | Implement /work-pipeline command for batch-merge-test pipelining | High | L | 7.3 | To do | ERI-27 |
| 7.12 [ORC] | Research claude-octopus and compare to claude-vibekanban | Low | S | — | To do | ERI-29 |
| 7.13 [ORC] | Research androsovm/clorch and compare to claude-vibekanban | Low | S | — | To do | ERI-30 |

### Task Details

**7.1 [ORC] — Design agent role architecture** *(ERI-56)*
- [ ] Define role schema: name, description, system prompt path, allowed commands, default autonomy
- [ ] Design role loading mechanism (file-based, e.g., `roles/architect.md`)
- [ ] Define how roles map to slash commands (e.g., Tester → `/work-task` with test focus)
- [ ] Design role context injection (how role prompt combines with task context)
- [ ] Document role extension points for custom/user-defined roles
- [ ] Consider interaction patterns: can roles collaborate on a single task?

**7.2 [ORC] — Create agent role prompt templates** *(ERI-57)*
- [ ] **PM role:** Drives PRD creation, plan reviews, prioritization, backlog grooming, re-planning on failures
- [ ] **Architect role:** Reviews PRDs, creates development plans, designs task breakdowns, reviews implementations
- [ ] **Tester role:** Writes test plans, creates unit/integration tests, validates acceptance criteria, runs regression
- [ ] **Developer role:** Implements tasks, fixes bugs, writes code, handles merge conflicts
- [ ] Each prompt should specify: persona, capabilities, constraints, output format expectations
- [ ] Include examples of role-appropriate decision-making

**7.3 [ORC] — Build orchestrator engine** *(ERI-58)*
- [ ] State machine: IDLE → PLANNING → ASSIGNING → EXECUTING → TESTING → REVIEWING → DONE
- [ ] Read current plan + VK task states to determine next action
- [ ] Role dispatch: select appropriate role for each action (PM for planning, Dev for coding, etc.)
- [ ] Parallel execution: identify independent tasks and launch concurrently (reuse `/work-parallel`)
- [ ] Completion detection: monitor task states, trigger next phase when prerequisites met
- [ ] Error handling: detect failures, route to appropriate role for recovery
- [ ] Event log: record all orchestrator decisions with rationale

**7.4 [ORC] — Add orchestrator configuration system** *(ERI-59)*
- [ ] Config file format (e.g., `.vibekanban/orchestrator.yml` or plan metadata section)
- [ ] Autonomy levels: `autonomous`, `gated`, `supervised`
- [ ] Per-phase gates: e.g., require human approval before merge but not before test
- [ ] Role overrides: disable specific roles, add custom roles
- [ ] Execution policies: max parallel tasks, retry limits, timeout thresholds
- [ ] Default config that's safe and conservative (gated mode)

**7.5 [ORC] — Integrate orchestrator with existing commands** *(ERI-60)*
- [ ] Map orchestrator actions to slash commands
- [ ] Planning phase: `/generate-prd` → `/prd-review` → `/create-plan` → `/generate-tasks`
- [ ] Execution phase: `/next-task` → `/work-task` or `/work-parallel`
- [ ] Completion phase: `/merge-parallel` → `/sync-plan` → `/commit-push`
- [ ] Status phase: `/plan-status`, `/session-status`
- [ ] Handle command failures gracefully within orchestrator loop

**7.6 [ORC] — Add orchestrator observability & controls** *(ERI-61)*
- [ ] Live status: show current phase, active roles, pending decisions
- [ ] Decision log: why each action was taken (e.g., "Selected task 2.1: highest priority, no blockers")
- [ ] Approval queue: pending human decisions with context
- [ ] Control commands: `/orchestrator pause`, `/orchestrator resume`, `/orchestrator status`
- [ ] Summary reports: after completion, show what was done, by which role, time taken

**7.7 [ORC] — Implement role-based task routing** *(ERI-62)*
- [ ] Default routing rules: Architect → design tasks, Developer → implementation, Tester → validation
- [ ] Pipeline routing: Architect review → Developer implement → Tester validate → PM approve
- [ ] Failure routing: test failure → Developer (with test output), design issue → Architect
- [ ] Configurable routing overrides in orchestrator config
- [ ] Support for multi-role tasks (e.g., Architect + Developer pair on complex task)

**7.8 [ORC] — Add autonomous testing & validation loop** *(ERI-63)*
- [ ] After Developer completes task, Tester role automatically activated
- [ ] Tester runs existing tests, writes new tests if needed
- [ ] Validate acceptance criteria from plan task details
- [ ] Pass → mark task done, update plan
- [ ] Fail → route back to Developer with failure context and Tester's analysis
- [ ] Configurable retry limit before escalating to human

**7.9 [ORC] — Research Claude Code Agent Swarm** *(ERI-17)*
- [ ] Evaluate architecture and approach
- [ ] Compare capabilities with claude-vibekanban orchestrator goals
- [ ] Document findings and potential inspiration

**7.10 [ORC] — Research parruda/swarm framework** *(ERI-18)*
- [ ] Evaluate architecture and approach
- [ ] Compare capabilities with claude-vibekanban orchestrator goals
- [ ] Document findings and potential inspiration

**7.11 [ORC] — Implement /work-pipeline command** *(ERI-27)*
- [ ] Design batch-merge-test pipeline flow
- [ ] Automate: select tasks → execute in parallel → merge → test → report
- [ ] Integrate with orchestrator engine (7.3)

---

## Epic 8: Kanban Adapter — [ADAPT] (NOT STARTED)

**Goal:** Abstract the kanban backend behind a pluggable adapter interface to support multiple providers.

### Acceptance Criteria
- [ ] Adapter interface defined with standard CRUD operations
- [ ] VibeKanban MCP adapter implemented as reference
- [ ] Architecture supports future backends (GitHub Projects, Linear, Jira, etc.)

### Tasks

| ID | Title | Priority | Complexity | Depends On | Status | VK |
|----|-------|----------|------------|------------|--------|----|
| 8.1 [ADAPT] | Kanban adapter interface and pluggable backend support | Medium | XL | — | To do | ERI-28 |

### Task Details

**8.1 [ADAPT] — Kanban adapter interface and pluggable backend support** *(ERI-28)*
- [ ] Design adapter interface with standard operations (list, create, update, delete issues)
- [ ] Implement VibeKanban MCP adapter as reference implementation
- [ ] Define extension points for custom backends
- [ ] Document how to add new adapter backends

---

## Dependency Graph

```
Epic 7 [ORC]: Agent Roles & Autonomous Orchestrator [HIGHEST PRIORITY]
  7.9, 7.10, 7.12, 7.13 (independent research)
  7.1 ──→ 7.2 ──→ 7.3 ──→ 7.4
                    │       │
                    │       └──→ 7.6
                    │
                    ├──→ 7.5 ──→ 7.8
                    │
                    ├──→ 7.7 ──→ 7.8
                    │
                    └──→ 7.11

Epic 1 [PAR]: Parallel Execution Stabilization
  1.1 ──┬──→ 1.6 ✓
  1.2 ──┤     ↑
  1.3 ──┴──→ 1.6 ✓
       ↓
  1.4 ──→ 1.5
  1.7, 1.8, 1.9, 1.10, 1.11, 1.12 (independent bugs/features)

Epic 2 [DEP]: Dependency Management
  2.1 ──→ 2.2
   │
   └──→ 2.4
  2.3 (independent)

Epic 3 [TRK]: Completion Tracking
  3.1 ──→ 3.2
   │
   └──→ 3.7
  3.3, 3.4, 3.5, 3.6, 3.8 (independent)

Epic 4 [REC]: Error Recovery
  4.1, 4.2, 4.4 (independent)
  4.3 ←── 1.3 (cross-epic)

Epic 5 [DX]: Developer Experience
  5.1, 5.2, 5.4, 5.5, 5.6, 5.7, 5.8 (independent)
  5.3 ←── 2.1 (cross-epic)

Epic 6 [DOC]: Documentation
  6.1 ←── 1.6 ✓, 3.1 (cross-epic)
  6.2 ✓, 6.3 ✓, 6.9 ✓, 6.11 ✓, 6.12 ✓ (done)
  6.4-6.8, 6.10 (independent)

Epic 8 [ADAPT]: Kanban Adapter
  8.1 (independent)
```

---

## Changelog

| Date | Action | Details |
|------|--------|---------|
| 2026-02-28 | Full VK sync | All 62 tasks linked to VK issues (ERI-1 through ERI-63). Marked 6 tasks Done based on codebase: 1.6, 6.2, 6.3, 6.9, 6.11, 6.12. Created 33 new VK issues for unlinked plan tasks. Updated 30 existing VK issue titles with plan task IDs. |
| 2026-02-28 | Epic 7 added | Agent Roles & Autonomous Orchestrator — 8 tasks, HIGHEST priority |
| 2026-02-07 | Plan created | Initial development plan with 6 epics, 25 tasks |

---

*This development plan was generated as part of dogfooding the claude-vibekanban workflow.*
