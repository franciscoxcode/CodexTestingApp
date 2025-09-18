Commit Convention

- Format: type: feature-name: short summary
- Types: feat, fix, refactor, docs, chore, test, build, ci, perf, style
- Feature name: kebab-case (lowercase letters, digits, hyphens)
- Summary: concise, English, ≤ 100 characters

Examples
- feat: task-row-interactions: tap opens note; left swipe edits
- fix: note-editor-autosave: prevent duplicate saves on blur
- chore: commit-convention: add commit template and hook

Tooling
- Template: .gitmessage.txt (used when not passing -m)
- Hook: .githooks/commit-msg validates format and length
- Git config: core.hooksPath = .githooks; commit.template = .gitmessage.txt

