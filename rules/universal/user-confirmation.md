# §6. Confirmation

## §6.1 Commits
Commit your own verified work locally without asking: stage only the files you changed (never `git add -A` over other work), and say in the message what changed and how it was verified.
Still ask before committing files you did not change in this session. Never commit on development, main or staging: create a feature branch instead, unless the project's `CLAUDE.md` says the repo works on main only.

## §6.2 Always ask first
- Pushing to any remote.
- Removing files or directories, except scratch and temporary files the agent created itself (seals, logs, scratch scripts, worktree leftovers): delete those without asking and report them in one line at most.
- Risky commands: sudo, rm -rf, database drops, production deployments.

## §6.4 Housekeeping is yours
Status files, logs, doc sync, test runs, format fixes and cleanup: do them without asking, and report them in one line at most, or not at all.
Ask him only about direction, priorities, product or business decisions, money, native-Khmer judgement, or facts only he knows.
Every request to him starts with the big picture: the goal, where things stand, and the next step.
Housekeeping never overrides §6.1 and §6.2.
