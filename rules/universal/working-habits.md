# Working Habits

Rules found nowhere else. Never copy the other universal rules here.

## Judgment and verification
- **"Is this correct?"** Read the code or config itself, say what it does now, say what it should do, and give a YES or NO verdict. Fix it if wrong. Never answer with history or "it depends".
- **Notebooks and data scripts:** before writing, open the real data files, confirm every file has the expected keys and parses, and dry-run the core logic in a temp script. A summary cell must not rely on variables from earlier cells unless it says so in a comment.
- **Sub-agent says "done":** before committing, grep for the new symbol, run the tests yourself, and open at least one changed file.
- **Version mismatch or dependency update:** edit the version, run the tests, and commit if they pass. "Wait for a live test" or "needs team approval" are not blockers.
- **He proposes merging two rules or conditions:** check whether they are really the same. If yes, merge them. If no, show one counterexample with real values before defending the split.

## Git and files
- **No AI credit in commits:** no `Co-Authored-By` lines for an AI and no "Generated with" lines. This overrides the tool's default.
- **Before changing code that already works:** tag the working commit, branch before the first edit, and use the same branch name in every repository the work touches.
- **Fresh-machine check after each task:** would it work from the committed files alone? New env var -> `.env.example` (and sync `.env*`); changed Dockerfile -> rebuild; new system package -> add it to the Dockerfile.
- **No hard line-wraps in prose:** one sentence, list item or paragraph is one physical line.
- **Public docs:** no unexplained ticket IDs or diagram-node letters, no internal history the reader does not need, no confusing number claims.
