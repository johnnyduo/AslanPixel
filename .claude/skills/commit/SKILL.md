---
name: commit
description: Generate a professional commit message from current changes (does NOT commit)
disable-model-invocation: true
argument-hint: "[optional context]"
allowed-tools: Bash(git *)
---

# Generate Commit Message

Analyze the current git changes and generate a professional commit message. **DO NOT run git commit** — only output the message for the user to copy.

## Steps

1. Run `git diff --stat` to see changed files
2. Run `git diff` to see the actual changes (use `--no-color` flag)
3. Run `git log --oneline -5` to match the repo's commit style
4. Analyze all changes and generate a commit message

## Commit Message Format

```
<type>: <subject line under 72 chars>

<body: 1-3 lines explaining what and why>
```

### Type Prefixes
- `feat:` — new feature
- `fix:` — bug fix
- `perf:` — performance improvement
- `refactor:` — code restructuring (no behavior change)
- `docs:` — documentation only
- `test:` — adding/updating tests
- `chore:` — build, CI, config changes
- `style:` — formatting, linting (no logic change)

### Rules
- Subject line: imperative mood ("add" not "added"), no period at end
- Body: explain the **why**, not just the **what**
- Keep it concise — no filler words
- If user provides context via arguments, incorporate it into the message
- Match the existing commit style of the repository

## Output Format

Output the commit message in a code block so the user can easily copy it. Do NOT run `git commit` or `git add`. Do NOT include `Co-Authored-By` or any co-author trailer — the user is the sole author.
