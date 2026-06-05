**Project Initialization Rule:** When the user says `initialize`, verify that every `.md` file inside `.claude/rules/` is explicitly imported via `@` in this `GEMINI.md` file. If any are missing, add them.

@CLAUDE.md
@.claude/rules/backend-standards.md
@.claude/rules/devops-standards.md
