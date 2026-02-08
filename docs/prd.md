# Product Requirements Document: Claude VibeKanban

> **Version:** 1.0
> **Date:** 2026-02-07
> **Author:** Claude Code (dogfooding)
> **Status:** Active

---

## 1. Executive Summary

Claude VibeKanban is a structured, prompt-driven development workflow that bridges product requirements and AI-powered task execution. It provides a complete pipeline from project idea to tracked, executable tasks using VibeKanban's MCP (Model Context Protocol) server.

**Core Mission:** Enable AI coding agents to work on well-defined, prioritized tasks with full context while maintaining a single source of truth for project status across the PRD → Plan → VibeKanban Board pipeline.

---

## 2. Problem Statement

### Current Challenges

1. **Context Loss Across Sessions:** AI agents start fresh each session, losing accumulated project knowledge and progress
2. **Unstructured Task Management:** Ad-hoc task handling leads to scope drift, missed dependencies, and unclear priorities
3. **No Single Source of Truth:** Project status scattered across conversations, boards, and documentation
4. **Manual Context Assembly:** Developers manually gather requirements, acceptance criteria, and dependencies before each task
5. **Limited Parallelism:** Single-agent execution bottlenecks; no coordination mechanism for multi-agent work
6. **No Completion Visibility:** After tasks complete, no record of what was done or how

### Impact

- Wasted time re-explaining context
- Tasks completed without meeting requirements
- Dependencies violated, blocking downstream work
- No velocity metrics or progress tracking
- Difficulty coordinating teams using AI agents

---

## 3. Goals & Success Metrics

### Primary Goals

| Goal | Description | Success Metric |
|------|-------------|----------------|
| **G1: Structured Planning** | Transform project ideas into actionable, prioritized task breakdown | 100% of tasks have acceptance criteria and dependencies defined |
| **G2: Context Preservation** | Maintain full project context across sessions | Agents can resume work without re-explaining requirements |
| **G3: Status Synchronization** | Keep plan and VK board in sync with drift detection | Zero undetected status discrepancies after sync |
| **G4: Intelligent Execution** | Guide agents to work on the right tasks in the right order | 90%+ tasks completed without dependency violations |
| **G5: Parallel Execution** | Enable multiple agents to work simultaneously | 2-5x throughput improvement for independent tasks |
| **G6: Completion Tracking** | Record what was implemented for each task | All completed tasks have completion logs |

### Non-Goals (Out of Scope)

- Replacing VibeKanban's core task management functionality
- Building a standalone CLI outside of Claude Code
- Supporting non-MCP agent protocols
- Real-time collaborative editing of plans
- Automated code review or merge approvals

---

## 4. User Personas

### Primary: AI-Assisted Developer

**Profile:** Software developer using Claude Code, Cursor, or similar AI coding assistants for daily work.

**Needs:**
- Quick onboarding to new projects
- Clear next steps without decision fatigue
- Confidence that work meets requirements
- Visibility into project progress

**Pain Points:**
- Re-explaining project context each session
- Uncertainty about task priority
- Missing hidden dependencies
- No record of AI-assisted changes

### Secondary: Engineering Lead

**Profile:** Team lead coordinating multiple developers and AI agents on shared codebases.

**Needs:**
- Progress visibility across all work streams
- Dependency management across team members
- Quality gates before merging
- Velocity metrics for planning

**Pain Points:**
- No central view of AI-assisted progress
- Merge conflicts from parallel work
- Inconsistent task completion quality
- Manual coordination overhead

---

## 5. Feature Requirements

### 5.1 Core Workflow Commands (Stable)

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F1.1 | PRD Generation | Interactive interview-style PRD creation from project idea | P0 |
| F1.2 | PRD Review | Analyze PRD for gaps, suggest epic structure, ask clarifying questions | P0 |
| F1.3 | Plan Creation | Generate development plan with epics, tasks, dependencies, acceptance criteria | P0 |
| F1.4 | Task Generation | Create VK tasks from plan with bidirectional ID linking | P0 |
| F1.5 | Plan Sync | Synchronize plan with VK status, detect and report drift | P0 |

### 5.2 Execution Commands (Stable)

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F2.1 | Task Execution | Execute specific task with full context assembly and AC verification | P0 |
| F2.2 | Next Task Recommendation | Score available tasks by priority, complexity, dependencies, unblocking potential | P0 |
| F2.3 | Work Next | Combine recommendation with execution for streamlined workflow | P1 |

### 5.3 Plan Management Commands (Stable)

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F3.1 | Plan Status | Read-only progress summary with epic completion percentages | P1 |
| F3.2 | Add Epic | Add new epic to existing plan with proper structure | P1 |
| F3.3 | Close Epic | Mark epic complete and update status | P1 |
| F3.4 | Workflow Reference | Show available commands and recommended flow | P2 |

### 5.4 Parallel Execution (Experimental)

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F4.1 | Local Parallel Sessions | Git worktree-based parallel execution with screen/tmux | P1 |
| F4.2 | Parallel Merge | Sequential merge with testing, VK updates, cleanup | P1 |
| F4.3 | Remote Delegation | Delegate to VK workspace sessions with chosen agent | P2 |
| F4.4 | Parallel Delegation | Delegate multiple independent tasks to parallel sessions | P2 |
| F4.5 | Session Status | Monitor all active work across local and remote sessions | P1 |

### 5.5 Completion Tracking

| ID | Feature | Description | Priority |
|----|---------|-------------|----------|
| F5.1 | Completion Logging | Append structured log to task description on completion | P0 |
| F5.2 | AC Verification | Track acceptance criteria completion in logs | P0 |
| F5.3 | Branch Tracking | Record branch name and key commits in logs | P1 |

---

## 6. Technical Requirements

### 6.1 Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| VibeKanban MCP Server | Required | Task management API |
| Claude Code | Required | Slash command host |
| Git | Required | Version control, worktrees |
| GNU Make | Required | Release automation |
| Bash | Required | Installation, scripting |
| screen or tmux | Optional | Parallel session management |

### 6.2 Data Model

**Development Plan Format:**
- Markdown-based for portability and human readability
- Epic-based hierarchical structure (Epic.Task numbering)
- VK ID comments for bidirectional linking: `<!-- vk:TASK_ID -->`
- Complexity sizing: S (<1hr), M (1-4hrs), L (4-8hrs), XL (8hrs+)
- Explicit dependency declarations using task IDs

**VK Integration:**
- MCP tool prefix: `mcp__vibe_kanban__`
- Task states: `todo`, `inprogress`, `inreview`, `done`
- VK is authoritative for task status
- Plan is authoritative for structure, dependencies, acceptance criteria

### 6.3 Command Structure

- Commands are markdown prompt files in `~/.claude/commands/`
- YAML frontmatter declares required MCP tools
- Consistent pattern: Read → Analyze → Propose → Confirm → Execute → Update
- Human-in-the-loop confirmation at every major decision point

---

## 7. User Experience

### 7.1 Workflow Progression

```
Project Idea
     ↓
/generate-prd  →  docs/prd.md
     ↓
/prd-review    →  Refined PRD with clarifications
     ↓
/create-plan   →  docs/development-plan.md
     ↓
/generate-tasks →  VK tasks with bidirectional links
     ↓
/work-next or /work-task  →  Implementation
     ↓
/sync-plan     →  Status synchronized, drift detected
```

### 7.2 Key Interaction Patterns

1. **Explicit Confirmation:** No autonomous actions; user approves each step
2. **Progressive Disclosure:** Show summary first, details on demand
3. **Graceful Fallbacks:** Commands work without VK (degraded mode)
4. **Clear Error Messages:** Explain what went wrong and how to fix

---

## 8. Constraints & Assumptions

### Constraints

1. **MCP Protocol Dependency:** All VK operations require MCP; no REST fallback
2. **Single Plan File:** One `development-plan.md` per project (no sharding)
3. **Parse-Modify-Write:** Plan updates not atomic; concurrent edits may conflict
4. **No VK Activity Log:** Completion logs appended to descriptions as workaround

### Assumptions

1. Users have Claude Code configured with VK MCP server
2. Projects use Git for version control
3. Tasks are small enough to complete in single agent sessions
4. Users follow recommended workflow order

---

## 9. Future Considerations

### Near-Term (v0.4-v0.5)

- Strict dependency enforcement mode
- Cycle detection for dependencies
- Improved error recovery in parallel execution
- Better session coordination messaging

### Medium-Term (v0.6-v1.0)

- VK Activity Log API integration (when available)
- Velocity metrics and burndown charts
- Multi-repository support
- Plan import/export (Jira, Linear, GitHub Projects)

### Long-Term (v1.0+)

- Web dashboard for progress visualization
- Slack/Teams integration for notifications
- AI coaching for stuck tasks
- Quality gate automation

---

## 10. Appendix

### A. Command Reference

| Command | Description | Version |
|---------|-------------|---------|
| `/generate-prd` | Create PRD from project idea | 0.3.1 |
| `/prd-review` | Review PRD and ask clarifying questions | 0.3.1 |
| `/create-plan` | Create development plan from PRD | 0.3.1 |
| `/generate-tasks` | Generate VK tasks from plan | 0.3.1 |
| `/sync-plan` | Sync plan with VK status | 0.3.1 |
| `/plan-status` | Show plan progress summary | 0.3.1 |
| `/next-task` | Recommend best next task | 0.3.1 |
| `/work-task` | Execute specific task | 0.3.1 |
| `/work-next` | Find and execute best next task | 0.3.1 |
| `/add-epic` | Add epic to plan | 0.3.1 |
| `/close-epic` | Mark epic complete | 0.3.1 |
| `/workflow` | Show command reference | 0.3.1 |
| `/work-parallel` | Launch parallel local sessions | 0.3.1-preview |
| `/merge-parallel` | Merge parallel branches | 0.3.1-preview |
| `/delegate-task` | Delegate to VK workspace session | 0.3.1-preview |
| `/delegate-parallel` | Delegate multiple tasks | 0.3.1-preview |
| `/session-status` | Check all active sessions | 0.3.1-preview |

### B. Glossary

| Term | Definition |
|------|------------|
| **MCP** | Model Context Protocol - standard for AI agent tool integration |
| **VK** | VibeKanban - the task management backend |
| **Epic** | Major feature or milestone containing multiple tasks |
| **AC** | Acceptance Criteria - testable conditions for task completion |
| **Tier 1** | Local parallel execution using git worktrees |
| **Tier 2** | Remote delegation using VK workspace sessions |
| **Drift** | Discrepancy between plan and VK status |

---

*This PRD was generated as part of dogfooding the claude-vibekanban workflow.*
