# Bulk Parallel Work Plan (Process Description)

What we've been doing is a pattern called **"Batch-Merge-Test Pipelining"**. Here's the process:

## 1. Dependency Graph Analysis

Before any work starts, analyze the full development plan's dependency graph to identify which tasks can safely run in parallel (no mutual dependencies, all prerequisites met). This produces a sequence of **batches** — groups of independent tasks that can execute simultaneously.

## 2. Batch Sequencing with Test Checkpoints

Instead of treating each batch independently, map the entire remaining backlog into a batch sequence upfront, then identify **natural testing checkpoints** where multiple batches converge into a testable feature:

```
Batch 1 (5 tasks) → merge → quick sanity check
Batch 2 (4 tasks) → merge
Batch 3 (13 tasks) → merge → CHECKPOINT 1: "Can I build flows visually?"
Batch 4 (3 tasks) → merge
Batch 5 (8 tasks) → merge → CHECKPOINT 2: "Full MVP end-to-end"
Batch 6 (5 tasks) → merge → CHECKPOINT 3: "Release-ready"
```

Checkpoints are placed where:
- Multiple epics intersect (frontend meets backend for the first time)
- A major user-facing feature becomes testable end-to-end
- Integration risk is highest (catching issues early saves the most rework)

## 3. Execution Cycle

For each batch, the cycle is:
1. **`/work-parallel [task IDs]`** — create worktrees, write task prompts, launch headless Claude sessions in screen
2. **Wait** — sessions run autonomously (5-15 min each), updating VK to "In review" when done
3. **`/session-status`** — check which sessions finished, which are stuck
4. **`/merge-parallel`** — merge all completed branches, update VK to "Done", clean up worktrees
5. **`/sync-plan`** — update the development plan with new progress percentages
6. **Repeat** with the next batch (newly unblocked tasks)

## 4. At Test Checkpoints — Stop and Validate

At designated checkpoints, pause the pipeline and:
- Run `make dev` to start both servers
- Manually test the feature set that just converged
- Fix integration issues before proceeding (parallel branches can't see each other's code)
- This is where you catch: API contract mismatches, store shape disagreements, CSS conflicts, import path issues

## 5. Key Differences from One-at-a-Time

| Aspect | One-at-a-time `/work-parallel` | Bulk plan |
|--------|-------------------------------|-----------|
| Planning | Per-batch, reactive | Full backlog mapped upfront |
| Checkpoints | Ad-hoc | Pre-identified based on feature convergence |
| Batch sizing | Default 3 | Sized by dependency layer (can be 5-13) |
| Context | Each batch is independent | Batches are sequenced toward milestones |
| Risk management | None | Integration risk drives checkpoint placement |

## 6. What Could Be Automated (Future)

A `/plan-bulk` or `/work-pipeline` command could:
- Parse the full dependency graph automatically
- Compute all batch layers (topological sort by dependency depth)
- Identify checkpoint candidates (cross-epic convergence points)
- Present the full pipeline plan for approval
- Execute batch-merge-sync cycles automatically, pausing only at checkpoints
- Resume after manual testing with a single command

This would reduce the current 6-command cycle (`work-parallel` → `session-status` → `merge-parallel` → `sync-plan` → repeat) to: **`/work-pipeline`** → test at checkpoints → **`/work-pipeline --continue`**.
