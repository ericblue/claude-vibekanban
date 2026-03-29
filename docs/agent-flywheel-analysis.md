# Agent Flywheel Analysis: Ideas for claude-vibekanban

**Source:** https://agent-flywheel.com/complete-guide (Jeffrey Emanuel)
**Date:** 2026-03-28
**Purpose:** Identify techniques from the Agent Flywheel methodology that could improve our workflow

---

## Executive Summary

The Agent Flywheel is a methodology for coordinating swarms of 5-12+ AI agents using exhaustive markdown planning, self-contained task units ("beads"), and graph-theory-based routing. The core philosophy — spend 85% of effort on planning before implementation — is a strong match for our existing PRD-first workflow but pushes several concepts much further than we currently do.

Our workflow already covers planning, task decomposition, parallel execution, and monitoring. The biggest gaps are in **multi-model planning synthesis**, **task self-containment**, **graph-aware task routing**, and **inter-agent coordination**.

---

## High-Value Ideas to Adopt

### 1. Multi-Model Plan Synthesis (HIGH IMPACT)

**What they do:** Get 4+ frontier models (Claude, GPT, Gemini, Grok) to independently design the same project, then synthesize the best ideas into a hybrid plan.

**Our gap:** `/generate-prd` and `/create-plan` use a single model. We miss blind spots that other models would catch.

**Adoption path:**
- Add a `/prd-review-multi` or enhance `/prd-review` to optionally send the PRD to multiple models and synthesize feedback
- Could use Claude Code's `WebFetch` or API calls to get competing perspectives
- Even a simpler version — having Claude argue both sides or role-play different reviewers — would help

**Effort:** Medium | **Impact:** High

---

### 2. Iterative Plan Convergence with Signals (HIGH IMPACT)

**What they do:** Run 4-5+ refinement rounds on the plan, stopping when suggestions become incremental, output length stabilizes, and change velocity decelerates.

**Our gap:** `/prd-review` does one pass. `/create-plan` generates the plan once. No convergence loop.

**Adoption path:**
- Add a convergence loop to `/create-plan` that runs multiple refinement passes
- Track metrics: number of changes per pass, severity of changes, output delta
- Stop when changes are incremental (convergence score > 0.75)
- Could be opt-in: `/create-plan --iterate`

**Effort:** Medium | **Impact:** High

---

### 3. Self-Contained Task Units / "Beads" (MEDIUM-HIGH IMPACT)

**What they do:** Each bead contains ALL context needed for implementation — no referring back to the plan. Includes embedded design rationale, explicit dependencies, comprehensive tests, and rich descriptions.

**Our gap:** Our tasks reference the plan for context. The `/work-task` command assembles context at runtime by reading the plan + VK. If context assembly fails or misses something, the agent struggles.

**Adoption path:**
- Enhance `/generate-tasks` to embed richer context in each VK task description: acceptance criteria, design rationale, relevant file paths, related tasks' interfaces
- Add a "bead polishing" step: multiple refinement passes on task descriptions before work begins
- Could add a `/polish-tasks` command that reviews and enriches task descriptions

**Effort:** Medium | **Impact:** Medium-High

---

### 4. Graph-Theory Task Routing (MEDIUM IMPACT)

**What they do:** Use PageRank, betweenness centrality, and HITS scoring to determine optimal task order. Agents query `bv --robot-triage` for the best next task based on graph metrics.

**Our gap:** `/next-task` uses a simpler heuristic: priority, complexity, epic order, unblocking potential. No graph-theory metrics.

**Adoption path:**
- Enhance `/next-task` to compute a dependency graph and score tasks by:
  - **Betweenness centrality:** Tasks that unblock the most downstream work
  - **Critical path:** Tasks on the longest dependency chain
  - **Fan-out:** Tasks with the most direct dependents
- This is a natural evolution of our existing "unblocking potential" heuristic

**Effort:** Medium | **Impact:** Medium

---

### 5. Agent Mail / Inter-Agent Communication (MEDIUM IMPACT)

**What they do:** Point-to-point messaging between agents, advisory file reservations with TTL expiry, coordination via thread_id = bead_id.

**Our gap:** Our parallel sessions are completely isolated. They can't negotiate file access or share discoveries. If two tasks end up touching shared files, we only find out at merge time.

**Adoption path:**
- Lightweight version: use a shared coordination file (e.g., `.agent-coordination/reservations.json`) in a shared location that all worktree agents can read/write
- File reservations would reduce merge conflicts significantly
- Could integrate with VK: tasks could have a "reserved files" field

**Effort:** High | **Impact:** Medium

---

### 6. AGENTS.md Operating Manual (LOW-MEDIUM IMPACT)

**What they do:** A single AGENTS.md file that every agent reads, containing behavioral rules, project conventions, tool docs, and core constraints (no file deletion, no destructive git, etc.).

**Our current approach:** We use CLAUDE.md for project-level instructions. This is essentially the same concept.

**Adoption path:**
- Document best practices for CLAUDE.md content specifically for parallel/swarm workflows
- Add a template section in the cookbook for multi-agent CLAUDE.md setup
- Ensure `/work-parallel` prompts include "re-read CLAUDE.md after context compaction" instruction

**Effort:** Low | **Impact:** Low-Medium

---

### 7. Single-Branch vs. Worktree Model (EVALUATE)

**What they do:** All agents commit to `main`, using advisory file reservations to prevent conflicts. No feature branches or worktrees.

**Our approach:** Git worktrees with separate branches per task, merged afterward.

**Analysis:** Their approach requires robust file reservation infrastructure (Agent Mail) and a pre-commit guard. Our worktree approach provides stronger isolation at the cost of merge complexity. **Our approach is likely better for most users** — it's safer and doesn't require custom tooling. However, for very large swarms (10+ agents), their single-branch model may have less overhead.

**Recommendation:** Keep our worktree model but add optional file reservation warnings (idea #5).

---

### 8. Fresh Eyes Technique (LOW EFFORT, HIGH VALUE)

**What they do:** When improvements plateau, start a new session with an agent that reads the full project context fresh, activating different reasoning patterns.

**Our gap:** Not formalized. Users might do this naturally by starting a new Claude Code session, but we don't prompt for it.

**Adoption path:**
- Add to `/work-parallel-loop`: after 2+ iterations with diminishing progress, suggest a "fresh eyes" pass
- Could be a standalone `/fresh-eyes` command that starts a new session focused on code review
- Integrate with cross-agent review: random code exploration activates different search behaviors

**Effort:** Low | **Impact:** Medium

---

### 9. Bead/Task Polishing Convergence (MEDIUM IMPACT)

**What they do:** 4-6+ refinement passes on task descriptions before implementation. Run deduplication, cross-reference against plan, check against existing codebase.

**Our gap:** `/generate-tasks` creates tasks once. No refinement loop.

**Adoption path:**
- Add `/polish-tasks` command or `--polish` flag to `/generate-tasks`
- Refinement passes: dedup check, dependency validation, AC completeness, codebase cross-reference
- Stop after convergence (similar to plan convergence in #2)

**Effort:** Medium | **Impact:** Medium

---

### 10. Structured Review Phases (MEDIUM IMPACT)

**What they do:** Self-review per task, cross-agent review every 30-60 min, alternating scrutiny modes, "Ultimate Bug Scanner" quality gate.

**Our gap:** `/merge-parallel` runs tests but doesn't do structured code review. No cross-agent review step.

**Adoption path:**
- Add a `/review-parallel` step between task completion and merge
- Each completed branch gets reviewed by a separate Claude session
- Use different review prompts to activate different bug detection patterns
- Could integrate with VK's `inreview` status — tasks stay in review until a review agent approves

**Effort:** Medium-High | **Impact:** Medium

---

### 11. Idea Wizard / Feature Generation (LOW PRIORITY)

**What they do:** Ground in reality, generate 30 ideas, winnow to 5, expand to 15, human picks, convert to beads.

**Our gap:** We don't have a brainstorming/ideation command.

**Adoption path:** Could add `/brainstorm` but this is lower priority — our workflow is focused on executing defined plans, not ideation.

**Effort:** Medium | **Impact:** Low

---

## Comparison Matrix

| Capability | Agent Flywheel | claude-vibekanban | Gap |
|---|---|---|---|
| Planning depth | 85% effort, multi-model, 5+ iterations | PRD -> plan (1 pass) | Large |
| Task granularity | Self-contained beads with full context | Plan references + VK descriptions | Medium |
| Task routing | Graph-theory (PageRank, betweenness) | Heuristic (priority, complexity, epic) | Medium |
| Parallel execution | 5-12 agents, single branch | 3 agents default, git worktrees | Different approach |
| Inter-agent coordination | Agent Mail, file reservations | None (isolated worktrees) | Large |
| Monitoring | bv dashboard, Agent Mail | screen/tmux, log files, VK status | Small |
| Review process | Self-review + cross-agent + UBS | Tests only at merge | Medium |
| Convergence tracking | Explicit convergence scores | Not tracked | Medium |
| Recovery from failure | Agent fungibility, reread AGENTS.md | Retry 2x, then skip | Similar |
| Autonomy level | Full loop with human tending | work-parallel-loop (similar) | Similar |

---

## Recommended Priority Order

1. **Iterative plan convergence** (#2) — Biggest bang for buck. Improves every downstream step.
2. **Multi-model plan synthesis** (#1) — Catches blind spots early. High leverage.
3. **Self-contained task units** (#3) — Makes parallel agents more reliable.
4. **Fresh eyes technique** (#8) — Very low effort, immediate value.
5. **Graph-theory task routing** (#4) — Natural evolution of `/next-task`.
6. **Structured review phases** (#10) — Quality gate before merge.
7. **Task polishing convergence** (#9) — Catches task-level issues before execution.
8. **Inter-agent communication** (#5) — High effort but reduces merge conflicts.
9. **AGENTS.md best practices** (#6) — Documentation improvement.
10. **Idea wizard** (#11) — Nice to have.

---

## Key Philosophical Takeaways

- **"Planning tokens are cheaper than implementation tokens"** — We should lean harder into this. Our 1-pass planning is leaving value on the table.
- **"Beads are executable memory"** — Tasks should stand alone without needing to refer back to the plan. This would make our parallel sessions more robust.
- **"Agent fungibility"** — All agents are generalists. No specialized roles. This matches our approach and validates it.
- **"Convergence, not iteration count"** — Track quality metrics, not just "did we do N passes." Apply this to plan refinement and task polishing.
- **"The human role is system design, not code writing"** — Our workflow already embodies this. The Flywheel just takes it further with more sophisticated coordination tooling.
