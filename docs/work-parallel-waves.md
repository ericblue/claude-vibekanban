  The Parallel Work Loop Pattern

  What we've been doing manually follows a repeatable algorithm:

  Algorithm

  INPUT: list of epics to complete (e.g., [3, 4])
  OUTPUT: all tasks done, merged, tested, pushed

  1. READ the development plan and VK status
  2. BUILD the full dependency graph across all target epics
  3. LOOP until all tasks in target epics are done:
     a. IDENTIFY available tasks:
        - Status is "todo" in VK
        - All dependencies are "done"
        - No mutual dependencies among candidates
     b. GROUP into a wave (max 5 parallel, configurable)
     c. CREATE worktrees + prompts for each task
     d. MARK tasks "in progress" in VK
     e. LAUNCH tmux/screen sessions
     f. POLL every 2 minutes:
        - Check tmux sessions (gone = done)
        - Check log files for SESSION_STATUS
        - If all done, continue
     g. MERGE all branches sequentially
        - Resolve conflicts (usually __init__.py / pyproject.toml)
     h. RUN tests + lint
        - If fail: stop, report, let user fix
     i. UPDATE VK status to "done"
     j. CLEANUP worktrees, branches, temp files
     k. REPEAT from (a) with newly unblocked tasks
  4. PUSH to remote
  5. REPORT summary

  Key differences from existing commands

  ┌───────────────────────┬────────────────────────────────────────────────┬───────────────────┐
  │        Command        │                  What it does                  │       Scope       │
  ├───────────────────────┼────────────────────────────────────────────────┼───────────────────┤
  │ /work-next            │ Pick 1 task, execute it inline                 │ Single task       │
  ├───────────────────────┼────────────────────────────────────────────────┼───────────────────┤
  │ /work-parallel        │ Pick N tasks, launch parallel sessions, return │ Single wave       │
  ├───────────────────────┼────────────────────────────────────────────────┼───────────────────┤
  │ /merge-parallel       │ Merge completed branches                       │ Post-wave cleanup │
  ├───────────────────────┼────────────────────────────────────────────────┼───────────────────┤
  │ /work-epic-loop (new) │ Orchestrate multiple waves end-to-end          │ Full epic(s)      │
  └───────────────────────┴────────────────────────────────────────────────┴───────────────────┘

  What /work-epic-loop would need to do differently

  1. Dependency-aware wave planning — Automatically compute waves from the dependency graph. We did this manually ("Wave A needs 4.1+4.5 first, then Wave B can do 4.2-4.7").
  2. Automatic merge + conflict resolution — The __init__.py and pyproject.toml conflicts were predictable (multiple agents creating the same package). The command could auto-resolve "ours" for these files.
  3. Test gate between waves — If tests fail after merging a wave, stop and report rather than launching the next wave on a broken base.
  4. Checkpoint awareness — The user could specify checkpoints ("stop after Epic 2 for manual testing") or it could auto-detect natural checkpoints (when an epic fully completes).

  Suggested invocation

  # Complete specific epics
  /work-epic-loop 3 4

  # Complete epics with checkpoint
  /work-epic-loop 3 4 --checkpoint-after-epic

  # Complete epics with max parallelism
  /work-epic-loop 3 4 5 --max-parallel 3

  # Dry run — show the wave plan without executing
  /work-epic-loop 3 4 --dry-run

  The prompt for the command would need

  1. The full wave-planning logic (read plan → build dependency graph → partition into waves)
  2. The launch/poll/merge/test loop (what we've been doing manually)
  3. Conflict resolution heuristics (auto-resolve __init__.py docstring conflicts, keep HEAD for pyproject.toml)
  4. Error recovery (if a session fails, report and continue with remaining tasks)
  5. VK status management throughout

  The main challenge is that this runs for 15-30+ minutes and needs to maintain state across multiple poll cycles. The current skill system isn't designed for long-running orchestration loops — it would need to
  be implemented as either a skill that calls itself recursively, or as a standalone script that uses claude -p for each wave.

  Want me to write this up as a formal skill definition?