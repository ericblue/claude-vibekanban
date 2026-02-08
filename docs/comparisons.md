# Comparisons

How claude-vibekanban compares to other AI-assisted development tools.

## TL;DR

Every tool listed here can run AI agents that write code. The difference is what happens *before* and *around* that:

| Gap | Who fills it | claude-vibekanban's approach |
|---|---|---|
| "What should I build?" | No one else | PRD generation through guided interview |
| "How do I break it down?" | No one else | Epic/task decomposition with dependencies and acceptance criteria |
| "Which tasks can run in parallel?" | Agent Teams (basic), no one else | Dependency graph analysis -- won't parallelize blocked tasks |
| "What agent should run this?" | No one else | Any MCP agent (Claude, Cursor, Codex, Gemini, Copilot) per task |
| "What's done across sessions?" | AutoMaker (app-internal), Agent Teams (session-scoped) | Persistent tracking via VK board + git-tracked plan file |
| "How do I merge parallel work?" | No one else | `/merge-parallel` with test gates, VK updates, worktree cleanup |

In short: other tools are **execution engines**. Claude-vibekanban is the **planning and coordination layer** that sits above them.

## At a Glance

| | claude-vibekanban | Agent Teams | AutoMaker | Claude Code (bare) | Cursor / Windsurf |
|---|---|---|---|---|---|
| **What it is** | Slash command workflow for Claude Code | Built-in multi-agent feature in Claude Code | Electron desktop app | CLI agent | IDE with AI |
| **Infrastructure** | None (markdown files) | None (built into Claude Code) | Electron + Express server | CLI binary | Full IDE |
| **Planning pipeline** | PRD → plan → tasks → execute | None | None (start at Kanban) | None | None |
| **Task tracking** | VibeKanban MCP + markdown plan | Shared task list (session-scoped) | Built-in Kanban UI | None | None |
| **Parallel execution** | Two-tier (local worktrees + remote sessions) | Native (independent Claude instances) | Multi-agent via Claude SDK | Manual | Manual |
| **Dependency analysis** | Yes (graph-aware task selection) | Basic (task-level blocks) | No | No | No |
| **Agent support** | Claude, Cursor, Codex, Gemini, Copilot, DROID | Claude only | Claude only | Claude only | Proprietary |
| **Persistence** | Across sessions (plan file + VK board) | Single session only | App-internal | Conversation logs | IDE state |
| **Customizable** | Edit markdown files | Configuration flags | Fork the app | Slash commands | Extensions |
| **Artifacts** | Portable markdown (git-tracked) | None (ephemeral) | App-internal state | Conversation logs | IDE state |

## vs AutoMaker

[AutoMaker](https://github.com/AutoMaker-Org/automaker) is an Electron desktop app where you describe features on a Kanban board and AI agents implement them automatically using the Claude Agent SDK.

**Where they overlap:** Both use Kanban-style task tracking, git worktree isolation, and multi-agent parallel execution.

**Where they diverge:**

| Dimension | claude-vibekanban | AutoMaker |
|---|---|---|
| **Setup** | `cp commands/*.md ~/.claude/commands/` | Install Electron app, run Express server, authenticate Claude CLI |
| **Workflow start** | Structured PRD and plan generation | Write a card on the board |
| **Agent choice** | Any MCP-compatible agent | Claude Agent SDK only |
| **Parallelism** | Dependency-aware (won't parallelize blocked tasks) | User-managed (drag cards to "In Progress") |
| **Plan artifacts** | Markdown files in your repo, version-controlled | Lives inside the app |
| **Review gates** | Multiple checkpoints throughout the workflow | Single "Waiting Approval" stage |
| **Runs inside** | Claude Code CLI (no new UI) | Dedicated desktop app |

**Choose AutoMaker if** you want a visual, self-contained desktop app with real-time agent monitoring and a polished drag-and-drop interface.

**Choose claude-vibekanban if** you want a structured planning-to-execution pipeline, dependency-aware parallelism, multi-agent flexibility, and zero infrastructure -- all inside the CLI you already use.

## vs Claude Code Agent Teams

[Agent Teams](https://code.claude.com/docs/en/agent-teams) is a built-in Claude Code feature (experimental, shipped with Opus 4.6) that lets you spin up multiple Claude instances working as a coordinated team. A lead session spawns teammates, each running in its own context window with direct inter-agent messaging and a shared task list.

**Where they overlap:** Both enable parallel AI-agent execution within the Claude Code ecosystem.

**Where they diverge:**

| Dimension | claude-vibekanban | Agent Teams |
|---|---|---|
| **Scope** | Full project lifecycle (requirements → plan → execute → merge) | Parallel execution within a single session |
| **Planning** | PRD generation, epic decomposition, acceptance criteria | None -- assumes you already know the tasks |
| **Task persistence** | Survives across sessions (VK board + plan file in git) | Session-scoped (lost on exit, no `/resume` support) |
| **Dependency model** | Project-level graph (epic dependencies, cross-task blocking) | Task-level blocks (within one session) |
| **Isolation** | Git worktrees (branch-per-task, no file conflicts) | Shared working directory (file conflict risk) |
| **Agent diversity** | Mix agents: Claude, Cursor, Codex, Gemini, Copilot | Claude only |
| **Merge workflow** | `/merge-parallel` with test gates and VK status updates | Manual |
| **Cost model** | Controlled (explicit session count, user approves before launch) | Scales linearly with teammates (each is a full Claude instance) |

**How they complement each other:** Agent Teams is an excellent *execution engine* for claude-vibekanban's Tier 1. VK handles the upstream work -- deciding what to build, decomposing it into tasks, identifying which are safe to parallelize -- then Agent Teams can execute those tasks as coordinated teammates. VK's `/work-parallel` already supports Agent Teams as a preferred launch mechanism.

**Choose Agent Teams alone if** your tasks are well-defined, independent, fit in a single session, and you don't need persistent tracking or a planning pipeline.

**Choose claude-vibekanban if** you need the full lifecycle: structured planning, persistent task tracking across sessions, dependency-aware scheduling, multi-agent-type support, and merge workflows. Use Agent Teams underneath as the parallel execution layer.

## vs Claude Code (bare)

Using Claude Code without any workflow tooling. You open a terminal, run `claude`, and work interactively.

**What claude-vibekanban adds:**

- **Structure** -- PRD generation, development plans with epics and dependencies, acceptance criteria per task
- **Persistence** -- Task status tracked in VibeKanban across sessions; plan file lives in the repo
- **Parallelism** -- Automated worktree setup, parallel session launch, and merge workflows
- **Continuity** -- `/sync-plan` detects drift between your plan and board; `/next-task` recommends what to work on based on priority, complexity, and dependencies
- **Reproducibility** -- The plan file documents what was built, why, and in what order

**What you give up:** Nothing. The slash commands are additive. You can still use Claude Code normally alongside them.

## vs Cursor / Windsurf / IDE Agents

IDE-integrated AI tools that provide inline code generation, chat, and agent capabilities within an editor.

| Dimension | claude-vibekanban | IDE Agents |
|---|---|---|
| **Scope** | Full project lifecycle (plan → build → review → ship) | File/function-level assistance |
| **Task tracking** | Built-in via VibeKanban MCP | External (Jira, Linear, etc.) |
| **Multi-agent** | Native (two-tier execution) | Single agent per session |
| **Planning** | Structured decomposition | Ad-hoc prompting |
| **Environment** | CLI-based | GUI editor |

These tools are complementary, not competitive. You can use claude-vibekanban for planning and orchestration while using Cursor as one of your execution agents via Tier 2 delegation.

## vs Aider / Other CLI Agents

[Aider](https://aider.chat) and similar CLI coding agents focus on interactive code editing with git integration.

**Key differences:**

- **Project scope** -- Aider operates at the file/commit level. VK operates at the project level (epics, plans, dependency graphs).
- **Multi-agent** -- Aider is single-session. VK orchestrates multiple parallel agents.
- **Task tracking** -- Aider has no task management. VK integrates with VibeKanban for persistent tracking.
- **Planning** -- Aider assumes you know what to change. VK helps you figure out what to build and in what order.

## Design Philosophy

The core difference between claude-vibekanban and most alternatives comes down to three principles:

1. **Planning before execution.** The hardest part of building software isn't writing code -- it's deciding what to build. Most AI tools skip straight to code generation. VK provides the upstream pipeline: requirements gathering, plan decomposition, dependency analysis.

2. **Composable, not monolithic.** Each slash command is an independent markdown file. Swap the task tracker, change the agent, modify the workflow -- nothing is tightly coupled. There's no app to maintain.

3. **Portable artifacts.** The development plan is a markdown file in your repo. It works without VibeKanban, without Claude Code, without any specific tool. It's readable by humans and any LLM.
