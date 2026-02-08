# Architecture & Execution Model

This document describes the current architecture of the VibeKanban slash command workflow, its execution model, known limitations, and future directions for multi-agent support.

## Current Execution Model

### Single-Agent, Sequential Execution

The slash commands are designed around a **single-agent, one-task-at-a-time** model. The core loop is:

```
/work-next → pick task → mark inprogress → implement → verify AC → mark done → repeat
```

Each command runs synchronously in the user's Claude Code session. There is no background processing, task queuing, or concurrent execution.

### State Management

State is stored in three places:

| Layer | Location | Role |
|-------|----------|------|
| **Development Plan** | `docs/development-plan.md` | Canonical plan: epics, tasks, dependencies, acceptance criteria |
| **VibeKanban** | MCP API | Authoritative task status (`todo`, `inprogress`, `inreview`, `done`) |
| **VK ID Links** | `<!-- vk:TASK_ID -->` in plan | Bidirectional sync between plan and VibeKanban |

**Source of truth:** VibeKanban owns task status. The plan file is the reference for structure, dependencies, and acceptance criteria. `/sync-plan` reconciles the two.

**Why maintain both?** The development plan exists as a portable, self-contained project briefing. It can be shared with collaborators, handed to any LLM (whether or not it has VK/MCP access), pasted into a GitHub issue, or read by a new agent that only has filesystem access. VK owns task status; the plan provides the full context -- epics, dependencies, acceptance criteria, progress -- in a single file that works everywhere. The sync keeps this portable artifact accurate.

### Context Assembly

When executing a task (`/work-task` or `/work-next`), the agent assembles context from multiple sources:

1. **Development plan** -- task table, epic context, acceptance criteria
2. **VibeKanban** -- current task status and details via `get_task`
3. **PRD** -- relevant requirements sections
4. **Codebase** -- existing code that the task will modify

This full-context approach is a key strength: each task execution has everything needed to implement correctly.

### Task Selection Algorithm

`/next-task` scores available tasks by:

1. **Dependency satisfaction** -- all `Depends On` tasks must be `done`
2. **Priority** -- High > Medium > Low
3. **Complexity** -- smaller tasks first (S > M > L > XL) for momentum
4. **Epic order** -- earlier epics first
5. **Unblocking potential** -- boost for tasks that unblock many others

### Dependency Handling

Dependencies are **checked but not enforced**. If a task's dependencies aren't met, the agent warns the user but allows them to proceed. This is intentional -- sometimes you need to work on things out of order -- but it means the system relies on user discipline rather than hard constraints.

## What Works Well

- **Guided workflow** from idea to shipped code across the full pipeline
- **Full context assembly** ensures the agent has PRD, plan, AC, and codebase context for every task
- **Drift detection** via `/sync-plan` catches stale tasks, dependency violations, and scope drift
- **Intelligent task selection** balances priority, complexity, dependencies, and unblocking potential
- **Agent-agnostic MCP calls** -- the underlying tool calls work with any MCP-compatible agent

## Known Limitations

### No Parallel Execution

The commands assume a single agent working on one task at a time. There is no:

- **Task locking** -- two agents could claim the same task simultaneously
- **Atomic plan updates** -- concurrent `/sync-plan` runs would overwrite each other
- **Event system** -- no way for agents to notify each other of task completion
- **Session coordination** -- no mechanism to partition work across agents

### Plan File Scaling

The markdown-based plan works well for small-to-medium projects but has inherent scaling limits:

- **Parse-modify-write** pattern has no atomic update guarantees
- **No indexing** -- finding a specific task requires parsing the entire file
- **Table readability** degrades beyond ~50-80 tasks per plan
- **No structured querying** -- all filtering is done by parsing markdown

### Dependency Model

- **Warnings only** -- dependencies are not hard blocks
- **No cycle detection** -- circular dependencies aren't caught automatically
- **Coarse-grained** -- dependencies exist between tasks, not subtasks
- **No critical path analysis** -- can't identify which tasks are on the critical path
- **Static** -- can't express conditional dependencies

### Status Tracking Gaps

- **No timestamps** -- can't determine when a task started or how long it took
- **No effort tracking** -- no actual vs. estimated complexity comparison
- **No velocity metrics** -- can't generate burndown or throughput data

## Multi-Agent Support: Current State

### What the MCP API Supports

The VibeKanban MCP server exposes `start_workspace_session`, which can spawn agent workspace sessions paired with a specific task and repository. Supported executors include:

- Claude Code
- Cursor
- Codex
- Gemini
- Copilot
- Custom agents (DROID, etc.)

This means the **backend infrastructure for multi-agent orchestration exists**.

### What the Slash Commands Use

Currently, **none of the slash commands invoke `start_workspace_session`**. All task execution happens directly in the user's Claude Code session via `/work-task` and `/work-next`. The MCP tools used are limited to:

- `list_projects`, `list_tasks`, `get_task` -- reading state
- `create_task`, `update_task` -- writing state

### The Gap

The MCP API can orchestrate multiple agents on the same project board, but the command layer doesn't tap into this capability. Bridging this gap is the primary avenue for expanding the project's execution model.

## Two-Tier Parallel Execution Model

Parallel execution is supported through two independent tiers, each suited to different use cases. Both tiers feed status back to the same VibeKanban board -- orchestration is handled by the slash commands, not by VibeKanban.

### Tier 1: Local Parallel Sessions (Git Worktrees)

**Use case:** "I want to knock out 3 independent tasks faster on my local machine."

[Git worktrees](https://git-scm.com/docs/git-worktree) allow multiple branches to be checked out simultaneously in separate directories, each with its own working copy. This eliminates the file conflict problem -- no two agents can step on each other's changes. Worktrees are the [officially recommended approach](https://code.claude.com/docs/en/common-workflows#run-parallel-claude-code-sessions-with-git-worktrees) for running parallel Claude Code sessions.

Each worktree runs a **full Claude Code session** (not a subagent). This is important because full sessions have MCP server access, which is required for communicating with VibeKanban (`update_task`, `get_task`, etc.). Subagents via the `Task` tool lack MCP access and cannot update VK status.

**Session launch options:**

| Mechanism | MCP access | Coordination | Setup |
|-----------|:---:|---|---|
| **[Agent Teams](https://code.claude.com/docs/en/agent-teams)** | Yes | Built-in: messaging, task claiming, shared task list | Lead spawns teammates into worktrees |
| **Headless `claude -p`** | Yes | Manual: poll for completion, check output files | Launched via Bash in each worktree |
| **Manual terminals** | Yes | Manual: user monitors each session | Command sets up worktrees, user launches `claude` in each |

Agent Teams is the preferred mechanism when available, as it provides built-in coordination between sessions. Headless mode or manual terminals work as fallbacks.

**Invocation modes:**

`/work-parallel` supports two modes:

- **Explicit:** User specifies task IDs directly -- `/work-parallel 1.3 2.1 3.2`. No analysis step, goes straight to confirmation.
- **Recommended:** No task IDs given -- `/work-parallel`. The LLM analyzes the backlog, identifies independent tasks with no mutual dependencies, and proposes a candidate set.

**Interaction flow:**

1. **Propose** -- LLM presents candidate tasks (or user provides them explicitly)
2. **Review** -- User sees the proposed set and can remove tasks, add tasks, or adjust the number. This is important for managing token usage and local resource consumption -- the LLM might identify 10 candidates, but the user may only want to run 3.
3. **Confirm** -- User approves the final set. No worktrees are created until confirmation.
4. **Execute** -- Worktrees and sessions are created and launched.

**Default concurrency cap:** 3 parallel sessions. The user can raise or lower this. The cap exists because each worktree + Claude Code session consumes tokens and local compute (memory, CPU, disk). Running too many in parallel can degrade performance or hit API rate limits.

**Task sources and branch naming:**

`/work-parallel` supports tasks from both the development plan and VibeKanban directly. Branch names are derived from the task source:

| Task source | Example branch name |
|-------------|---------------------|
| Plan task `2.3` titled "Add user API" | `task/2.3-add-user-api` |
| VK-only task titled "Fix login bug" | `task/fix-login-bug` (slugified title) |
| Ambiguous or untitled VK task | `task/<short-vk-uuid>` |

**VK-only tasks** (created manually in VibeKanban, not linked to the plan) are supported but come with a caveat: they typically lack dependency information and acceptance criteria. Since `/work-parallel` relies on dependency analysis to confirm tasks are safe to run concurrently, VK-only tasks will trigger a warning during the review step. The user can still include them, but should verify independence manually.

**Worktree directory convention:**

All worktrees are created under a dedicated sibling directory: `../<project-name>-worktrees/`. This keeps them grouped and predictable without cluttering the parent directory.

```
~/Development/
  myproject/                              # main working directory
  myproject-worktrees/
    task-2.3-add-user-api/                # worktree for plan task 2.3
    task-fix-login-bug/                   # worktree for VK-only task
    task-3.1-setup-database/              # worktree for plan task 3.1
```

The worktree directory name mirrors the branch name. `/work-parallel` reports all paths when it creates them. You can always find active worktrees with `git worktree list`. After branches are merged, worktrees are cleaned up with `git worktree remove`.

**How it works (after confirmation):**

1. Create the worktrees directory if it doesn't exist (`mkdir -p ../<project>-worktrees`)
2. Create a git worktree and branch for each approved task (`git worktree add ../<project>-worktrees/task-2.3-add-user-api -b task/2.3-add-user-api`)
3. Mark tasks `inprogress` in VibeKanban via `update_task` (non-blocking on failure)
4. Launch a full Claude Code session in each worktree (via Agent Teams, screen/tmux sessions, background processes, or manual terminals)
5. Each session has MCP access and implements its task with full context (PRD, plan, acceptance criteria)
6. Sessions update VibeKanban status directly via `update_task` (mark `inreview` when done)
7. After review and merge, clean up worktrees (`git worktree remove ../<project>-worktrees/task-2.3-add-user-api`)

**Strengths:**

- Full file isolation -- each session has its own working directory, no conflict risk
- Branch-per-task -- clean git history, standard merge workflow
- Independent environments -- each worktree can have its own dependencies/state
- Officially supported by Claude Code
- Shared git history and remote connections across all worktrees
- User always has final say on what runs and how many

**Permissions and user input:**

Parallel sessions need to run with minimal interruption. Permission prompts that block on user input are a practical problem when multiple sessions are running simultaneously.

| Launch mechanism | Permission handling | User input |
|--|--|--|
| **Agent Teams** | Teammates inherit the lead's permission mode. Prompts bubble up to the lead. | Teammates can message the lead to ask questions. Lead relays to user if needed. |
| **Headless `claude -p`** | Non-interactive -- **cannot respond to permission prompts**. Sessions will block or fail. | No user input possible. Agent must work fully autonomously. |
| **Manual terminals** | Normal interactive prompts in each terminal. | User switches between terminals to respond. |

**For headless mode**, one of these is required:

- `claude -p --dangerously-skip-permissions` -- skips all permission checks. Fast but risky; use only for trusted, well-scoped tasks.
- Pre-configured `~/.claude/settings.json` with `allowedTools` that includes the tools the agent needs (Bash, Write, Edit, MCP tools, etc.) -- more controlled than skipping all permissions.
- `--permission-mode bypassPermissions` -- accepts all tool calls without prompting.

**For Agent Teams**, set the lead's permission mode before spawning teammates. All teammates inherit it. `--dangerously-skip-permissions` on the lead propagates to all teammates.

**For manual terminals**, the user can respond to prompts in each terminal, but must actively monitor all sessions. This works best with 2-3 sessions.

**When a session needs clarification (not just permissions):** If the agent encounters ambiguity or needs a design decision, behavior depends on the mechanism:
- **Agent Teams**: Teammate messages the lead, which can relay to the user or make a decision.
- **Headless mode**: Session fails or makes a best-guess decision. To avoid this, ensure task descriptions and acceptance criteria are detailed enough for autonomous work.
- **Manual terminals**: Agent prompts in that terminal. User switches to respond.

**Observability and session monitoring:**

A key practical concern with parallel sessions is visibility: how do you know what a session is doing, whether it's stuck, or what it produced?

| Launch mechanism | Real-time visibility | Attach mid-session | Post-session output |
|--|--|--|--|
| **Agent Teams** | Teammate messages appear in the lead's session | No direct attach; lead sees messages but not full session activity | No persistent log (team state is lost on cleanup) |
| **Screen/tmux sessions** | `screen -r` / `tmux attach` to observe live output | Read-only observation during `claude -p` execution; full interactive input during failure recovery mode | Log file via screen's `-L` / tmux's `pipe-pane`; `screen -ls` / `tmux list-sessions` for health checks |
| **Background processes** | `tail -f` on log file | No interactive attach; read-only log tailing only | Output file via redirect; `--output-format stream-json` for structured output |
| **Manual terminals** | Full visibility (you're watching each terminal) | Already attached | Terminal scrollback |

Screen and tmux provide the recommended balance of observability and recovery. During normal `claude -p` execution, attaching to a screen/tmux session provides read-only observation of the agent's work. If the agent fails (non-zero exit), a wrapper script automatically launches interactive `claude` in the same session and worktree. The user simply attaches to continue where the agent left off. `screen -ls` serves as a natural health check: session gone = completed successfully; session still alive after expected time = either still running or in interactive recovery mode.

**Practical mitigations:**

- **Screen/tmux is the primary mechanism** for headless session observability. `/work-parallel` auto-detects screen or tmux at runtime and launches sessions inside managed screen/tmux sessions with failure recovery. Attach to observe progress (`screen -r claude-task-2.3`), check health (`screen -ls`), and detach without stopping (`Ctrl-A D`).

- **Log files are always created** regardless of launch mechanism. Screen uses its built-in `-L -Logfile` flag; tmux uses `pipe-pane`. These avoid piping through `tee`, which would cause block buffering and blank screen sessions. Background processes redirect directly. Logs are stored at `../<project>-worktrees/task-<id>.log`.

- **For Agent Teams**, the lead acts as a natural aggregation point. Teammates message the lead with progress updates. The lead can relay status to the user.

- **For manual terminals**, use a terminal multiplexer like `tmux` or iTerm2 split panes to watch all sessions simultaneously.

- **VK task status is always available** regardless of launch mechanism. All sessions update VK via `update_task`, so running `/session-status` or checking the VK board shows which tasks are `inprogress`, `inreview`, or `done` -- even when you can't see the session output directly.

- **Git activity is observable.** Since each session works in its own worktree, you can check branch activity: `git -C ../myproject-worktrees/task-2.3-add-user-api log --oneline -5` shows recent commits, which is a good proxy for progress.

**Considerations:**

- Each worktree may need its own environment setup (dependency install, etc.)
- Merge conflicts are possible when integrating branches back to main
- Multiple Claude Code sessions consume more resources than a single session
- Plan file updates should be serialized -- only one session runs `/sync-plan` at a time
- Token costs scale linearly with the number of parallel sessions

**Why not subagents (Task tool)?** Claude Code's `Task` tool spawns lightweight subagents within the current session. These are useful for parallel read-only work (research, analysis, code review), but they **lack MCP server access** -- meaning they cannot communicate with VibeKanban to update task status. They also share the same filesystem, introducing file conflict risks. For task implementation that requires VK integration, full Claude Code sessions (via Agent Teams, headless mode, or manual terminals) are required.

### Tier 2: Remote Delegation (VibeKanban Workspace Sessions)

**Use case:** "I want to hand this task to a separate agent entirely."

VibeKanban's `start_workspace_session` MCP tool spawns an entirely separate agent session managed by VK. This can be a different Claude Code instance, or a different agent altogether.

**Supported executors:** Claude Code, Cursor, Codex, Gemini, Copilot, DROID, and custom agents.

**How it works:**

1. Identify a task to delegate
2. Call `start_workspace_session` with the task ID, executor type, and repo/branch
3. VK launches a separate agent session paired with that task
4. The remote agent works independently in its own environment
5. Status updates flow back to VibeKanban automatically

**Strengths:**

- True isolation -- separate environment, no file conflicts
- Agent flexibility -- choose the best agent for the task
- Branch-based -- each session can work on its own branch
- Session history -- VK preserves the full agent session, so you can review what the agent did even after the session closes
- Built-in code review -- VK provides diff views, inline commenting, and the ability to send revision requests back to the agent in the same feature branch
- One-click merge -- merge the branch to main directly from the VK UI; task automatically moves to `done`

**Risks:**

- Heavier setup -- separate session startup time
- Branch merge conflicts when integrating work back
- Less visibility into progress from the orchestrating session
- Session lifecycle management (timeouts, failures, retries)

**Current status:** The MCP API supports this, but the slash commands don't yet invoke it. Requires further testing of the workspace session lifecycle.

### Separation of Concerns

| Concern | Owner |
|---------|-------|
| Task status (todo/inprogress/done) | VibeKanban MCP API |
| Task structure, dependencies, AC | Development plan file |
| Execution orchestration | Slash commands (independent of VK) |
| Local parallelism | Git worktrees + Claude Code sessions (Tier 1) |
| Remote agent delegation | VK `start_workspace_session` (Tier 2) |

This separation keeps the commands portable and independent. VK is the shared board, not the execution engine. The slash commands can evolve their orchestration model without coupling to VK internals.

### Planned Commands (Experimental)

| Command | Tier | Description |
|---------|------|-------------|
| `/work-parallel` | 1 | Analyze backlog, identify independent tasks, set up worktrees, and launch parallel Claude Code sessions |
| `/delegate-task` | 2 | Start a VK workspace session for a specific task with a chosen agent |
| `/delegate-batch` | 2 | Delegate multiple independent tasks to parallel workspace sessions |
| `/session-status` | 2 | Check status of all active workspace sessions |

### Areas Requiring Further Testing

The following need validation before these commands are production-ready:

1. **Tier 1 -- Worktree lifecycle:** What's the best automation for creating, setting up (dependency install), and tearing down worktrees per task? How should branch naming conventions work?

2. **Tier 1 -- Merge strategy:** When multiple worktree branches are ready, what's the best merge order? How should merge conflicts between concurrent task branches be handled?

3. **Tier 1 -- Environment setup:** Each worktree may need its own dependency install, dev server, etc. How much of this can be automated?

4. **Tier 2 -- Workspace session lifecycle:** How does `start_workspace_session` behave end-to-end? What happens when a session completes, fails, or times out?

5. **Concurrent status updates:** When multiple agents (local or remote) update task status simultaneously, does the MCP API handle this correctly?

6. **Cross-agent dependency coordination:** If Agent A completes task 1.1 and Agent B is waiting on it, how should the handoff work?

7. **Plan file concurrency:** With multiple agents completing tasks, plan sync should be serialized -- only one session runs `/sync-plan` at a time.

8. **Error handling and recovery:** How should failed sessions (local or remote) be detected and reassigned?

### Design Principles

- **VibeKanban remains source of truth** -- all agents read/write status through the MCP API
- **Orchestration is independent** -- the slash commands manage execution, not VK
- **Plan file becomes read-mostly** -- sync operations should be serialized
- **Graceful degradation** -- parallel features are additive; the single-agent `/work-next` loop continues to work unchanged
- **Explicit over implicit** -- parallel execution and delegation are conscious user actions, not automatic

## Relationship to Claude Code Agent Teams

[Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams) is an experimental feature that coordinates multiple Claude Code instances working together: a lead assigns tasks, teammates execute in parallel, and agents message each other directly.

### Complementary, not competing

Agent Teams and this workflow operate at different layers:

| Layer | This workflow | Agent Teams |
|-------|---------------|-------------|
| **Planning** | PRD generation, epic/task breakdown, dependency analysis, acceptance criteria | No planning pipeline |
| **Task decomposition** | Structured plan with priorities, complexity, dependencies | Flat task list with basic dependencies |
| **Delegation intelligence** | Dependency analysis identifies what's safe to parallelize | Lead assigns; no dependency-aware analysis |
| **Execution coordination** | Subagents + worktrees (Tier 1), VK workspaces (Tier 2) | Shared task list, inter-agent messaging, self-claiming |
| **Verification** | Per-task acceptance criteria checked before marking done | No AC concept |
| **Persistent tracking** | VK board + plan file survive across sessions | Team state lost on cleanup |
| **Multi-agent support** | VK workspaces spawn any MCP-compatible agent | Claude Code only |

This workflow provides the **structured thinking layer** -- what to build, how to break it down, what's safe to parallelize, and what "done" means. Agent Teams provides the **runtime coordination layer** -- real-time messaging, task claiming with locking, split-pane visibility.

### Agent-agnostic infrastructure

While the slash commands are Claude Code markdown prompts, the underlying infrastructure is agent-agnostic:

- The **VibeKanban MCP API** works with any MCP-compatible agent (Cursor, Codex, Gemini, Copilot, etc.)
- The **development plan** is a markdown file any agent can read
- The **MCP tool calls** (`create_task`, `update_task`, `get_task`) are identical regardless of which agent makes them
- **`start_workspace_session`** can spawn any supported executor type

The slash commands are the Claude Code interface to a shared infrastructure that any agent can participate in. A Cursor agent can read the same plan, pick up a VK task, and update status through the same MCP API.

### Using both together

The most powerful setup combines both:

1. Use this workflow for planning: `/generate-prd` -> `/create-plan` -> `/generate-tasks`
2. Use Agent Teams for parallel execution: spawn teammates that each pick up a VK task
3. Teammates use VK's MCP API to mark tasks `inprogress`/`done`
4. Use `/sync-plan` to reconcile everything afterward

This gives you structured decomposition + real-time coordination + persistent tracking.

### When to use each alone

| Scenario | Better fit |
|----------|------------|
| Greenfield project needing full planning pipeline | This workflow |
| Quick parallel research or code review | Agent Teams |
| Long-running project with progress tracking across sessions | This workflow |
| Debugging with competing hypotheses | Agent Teams |
| Multi-agent-type orchestration (Cursor + Claude + Codex) | This workflow (Tier 2) |
| Real-time agent collaboration and debate | Agent Teams |
| Structured task execution with AC verification | This workflow |

## Human-in-the-Loop Philosophy

### Why human oversight is central to this workflow

Every command in this workflow includes explicit human decision points. This is a deliberate design choice, not a limitation. The workflow is built around the principle that **AI should handle the grunt work while humans make the judgment calls**.

### Where humans are in the loop

| Phase | Human role | What the agent handles |
|-------|-----------|----------------------|
| **PRD generation** (`/generate-prd`) | Answers interview questions, provides domain knowledge | Structures requirements, identifies gaps |
| **PRD review** (`/prd-review`) | Responds to clarifying questions, refines scope | Identifies ambiguities, suggests epic structure |
| **Plan creation** (`/create-plan`) | Reviews and approves the plan | Generates epics, tasks, dependencies, AC |
| **Task generation** (`/generate-tasks`) | Approves task creation | Creates VK tasks, links them to the plan |
| **Task selection** (`/next-task`, `/work-next`) | Confirms or overrides the recommended task | Scores candidates, considers dependencies/priority/complexity |
| **Task execution** (`/work-task`, `/work-next`) | Reviews implementation, decides when to mark done | Implements code, verifies acceptance criteria |
| **Parallel setup** (`/work-parallel`) | Reviews candidate set, adjusts count, chooses permissions, confirms | Analyzes dependencies, identifies safe parallelization |
| **Code review** (post-execution) | Reviews diffs, tests branches, merges to main | Marks tasks `inreview`, creates PRs |
| **Plan sync** (`/sync-plan`) | Reviews drift reports, decides on corrections | Detects stale tasks, dependency violations, scope drift |

### Key design decisions reflecting this philosophy

1. **Confirm before execute.** `/work-next` presents the recommended task and waits for confirmation before writing any code. `/work-parallel` shows the full execution plan and does not create worktrees until the user explicitly approves.

2. **`inreview` as a first-class status.** The workflow distinguishes "agent says it's done" from "human verified it's done." For parallel and branched work, tasks go to `inreview` first. The human reviews, tests, and only then marks `done`. This is the quality gate.

3. **Dependencies are warnings, not blocks.** The agent warns when dependencies aren't met but lets the user proceed. Humans understand context that dependency graphs can't capture -- maybe the dependency is nearly done, or the task can be partially implemented without it.

4. **No autonomous loops.** The commands do not loop automatically. Each task requires a new invocation (`/work-next` again). There is no "run until the backlog is empty" mode. This prevents runaway token consumption, ensures the human stays engaged with progress, and makes it easy to pause and redirect.

5. **Permission model is explicit.** For parallel sessions, the user explicitly chooses how permissions are handled. Even the most permissive option (`--dangerously-skip-permissions`) requires a conscious user decision during the `/work-parallel` setup flow.

### Comparison with fully autonomous approaches

Some tools, like [Ralph](https://github.com/frankbria/ralph-claude-code), take a different approach: continuous autonomous execution loops where the agent iterates on the project with minimal human intervention.

| Aspect | This workflow | Fully autonomous (e.g., Ralph) |
|--------|--------------|-------------------------------|
| **Execution model** | Human confirms each step; no auto-loop | Continuous loop; agent iterates until EXIT_SIGNAL |
| **Planning** | Structured pipeline: PRD → plan → tasks → execute | Reads a prompt file (PROMPT.md); no structured decomposition |
| **Task selection** | Human approves recommended task before execution | Agent decides what to work on next |
| **Quality gates** | `inreview` status, AC verification, human review | Circuit breakers, rate limits, stuck-loop detection |
| **Safety mechanism** | Human judgment at decision points | Automated guardrails (rate limiting, error detection, session expiry) |
| **Progress tracking** | VK board + plan file with drift detection | Git commits counted as progress, checkbox completion |
| **Parallel execution** | Structured: dependency analysis, worktrees, user-approved sets | Sequential within a single loop |
| **Token management** | Human controls scope (task count, parallelism cap) | Rate limiting (100 calls/hour), session timeout (24h) |
| **Best for** | Projects needing structured planning, quality gates, and multi-agent coordination | Rapid iteration on well-scoped tasks where speed matters more than review |

Neither approach is universally better. The right choice depends on the project's risk tolerance, complexity, and how much human judgment the work requires:

- **Use a human-in-the-loop workflow (this project)** when: the project needs structured planning and decomposition, tasks have complex dependencies, quality matters more than speed, you want persistent tracking across sessions, or you're coordinating multiple agents/agent types.

- **Use a fully autonomous loop** when: the project scope is well-defined and contained in a prompt file, tasks are straightforward enough that the agent can self-evaluate, speed of iteration matters more than review, and you trust the agent to make good decisions within the guardrails.

- **They can complement each other.** Use this workflow for the planning phase (PRD → plan → tasks), then use an autonomous loop for execution of individual well-scoped tasks. The structured planning ensures each task handed to the autonomous loop has clear acceptance criteria and boundaries.

## Summary

The current architecture is well-suited for its primary use case: a single developer (or AI agent) working through a backlog methodically with full context. The `/work-next` loop is the project's sweet spot.

The two-tier parallel execution model extends this with local worktree-based parallelism (Tier 1) and remote workspace delegation (Tier 2). Both are experimental and actively being tested.

The workflow is complementary to Claude Code Agent Teams: this project provides planning, task decomposition, and delegation intelligence; Agent Teams provides runtime coordination. The underlying infrastructure (VK board, plan file, MCP API) is agent-agnostic and supports orchestration across multiple agent types. The core design principle is that orchestration stays independent of VibeKanban -- VK is the shared board, the commands handle how work gets done.
