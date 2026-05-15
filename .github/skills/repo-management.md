---
name: repo-management
description: 'Git and gh CLI operations: clone, branch, commit, push, PR — every git action goes through this skill.'
---

# Skill: repo-management

What the `repo-manager` agent knows how to do.

## Capabilities

- Validate and parse git URLs (HTTPS/SSH).
- Clone with shallow depth, deepen on demand.
- Detect current default branch from `origin`.
- Create, rename, and reuse local branches with conflict resolution.
- Lint Conventional Commit messages.
- Detect branch divergence and rebase safely.
- Push with explicit user approval.
- Open PRs via `gh` with body from a prerendered file.

## Interfaces

```
clone(url)                       -> {repoPath, defaultBranch}
branch(name, base)               -> {branch}
commit(message, paths[])         -> {sha}
push(force=false)                -> {remote, branch, ahead, behind}
pr(target, title, bodyFile)      -> {url}
```

## Guardrails

- Refuses force-push unless user explicitly types `force`.
- Refuses to operate on a dirty working tree before push.
- Never modifies `.git/config` user identity.
- Never deletes branches.

## Logs

Every action appends to `.aidlc/runs/<runId>/repo-manager.log`.
