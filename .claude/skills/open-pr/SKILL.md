---
description: Run precommit checks, write a PR description, get approval, and open the PR on GitHub. Usage: /open-pr [base-branch] (e.g. /open-pr main)
disable-model-invocation: true
---

## Your task

Determine the base branch: use the one in the invocation (e.g. `/open-pr main`) if given, otherwise ask "Which branch should this PR target? (e.g. main, develop)" and wait. Then confirm the current branch with `git branch --show-current`.

### Step 1 — Gather diff context

```
git log <base-branch>..HEAD --oneline
git diff <base-branch>..HEAD --name-only
git diff <base-branch>..HEAD
```

### Step 2 — Run precommit checks

Run `mix precommit` (compile, Credo strict, tests). If it fails, **stop immediately**, report the failures, and do not proceed until they're resolved.

### Step 3 — Write the PR description

Using the diff context from Step 1, extract:

- The main purpose of the changes
- Which parts of the system are affected
- Whether this is a feature, fix, refactor, or other type of change
- Any issue numbers referenced in commit messages or branch name (e.g. branch `452-link-staff-member-to-classes` → issue #452)

Craft the description: focus on WHAT and WHY (not HOW), present tense and active voice, specific about functionality ("Adds support for linking staff members to classes", not "Updates staff members"), mindful of the educational domain (student/teacher/admin, assessment, learning management). Use this structure:

```
### Summary

A brief 1-2 sentence overview of what this PR accomplishes.

### Related Issues

- Closes #[issue-number]

### What This PR Does

A clear explanation of the functionality added, changed, or fixed:

- New features or capabilities introduced
- Problems solved or bugs fixed
- Improvements to existing functionality
- User-facing changes

### Impact and Scope

- Which parts of the system are affected
- Which features or modules are touched
- Any breaking changes or migration requirements

### Testing Considerations

(Include if relevant)

- Key scenarios covered by tests
- Edge cases considered

### Additional Notes

(Include if relevant)

- Deployment considerations
- Follow-up tasks

---

Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: [model] <noreply@anthropic.com>
```

### Step 4 — Ask for approval

Present the full description and ask: "Does this PR description look good? Reply **yes** to open the PR, or provide feedback to revise it." Do not proceed until the user approves; if they give feedback, revise and ask again.

### Step 5 — Create the PR

Once approved, run the following (Summary line as the title), then display the PR URL:

```
gh pr create --base <base-branch> --title "<summary line>" --body "<approved description>"
```
