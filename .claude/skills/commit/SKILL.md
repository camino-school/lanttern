---
description: Craft a Conventional Commit message and create the commit
disable-model-invocation: true
---

## Context

- Staged files: !`git diff --cached --name-only`
- Staged diff: !`git diff --cached`
- Unstaged changes: !`git status --short`
- Recent commits (for style reference): !`git log --oneline -10`
- Current branch: !`git branch --show-current`

## Your task

Analyze the staged changes above and create a Conventional Commit. If no files are staged, tell the user and stop.

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

- **type**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, or `chore`.
- **scope**: the module/area affected (`auth`, `contexts`, `live`). Omit if the change spans unrelated areas.
- **description**: ≤72 chars, imperative mood ("add" not "added"), no capital after the colon, no trailing period. Describe WHAT changed conceptually, never file names or line numbers.
- **body** (optional): WHY the change was made and any non-obvious implications. Wrap at 72 chars.
- **footer** (optional): `BREAKING CHANGE: …`. Do NOT add issue references (Closes/Fixes #N) unless the user explicitly asks — those belong in the PR description.

Write for the developer reading this in 6 months, using domain language (assessment, LiveView, contexts, schemas). For multi-file changes, describe the unified goal, not each file.

### Authorship

Append these two lines at the end (after a blank line if there's no other footer); `[model]` matches the current model, e.g. "Claude Opus 4.8":

```
Generated with Claude Code
Co-Authored-By: [model] <noreply@anthropic.com>
```

Then create the commit. Do not explain the message — just commit and show the git output.
