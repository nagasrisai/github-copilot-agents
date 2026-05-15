#!/usr/bin/env bash
# push-and-pr.sh — stage 9 of the AIDLC flow.
# Pushes the working branch and opens a PR. Asks the user for the PR target branch.
#
# Usage: push-and-pr.sh <runId>

set -euo pipefail

RUN_ID="${1:?runId required}"
AIDLC_HOME="${AIDLC_HOME:-$(pwd)/.aidlc}"
RUN_DIR="$AIDLC_HOME/runs/$RUN_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AIDLC_RUN_ID="$RUN_ID"

REPO_PATH="$(jq -r .repoPath "$RUN_DIR/repo.json")"
BASE_BRANCH="$(jq -r .baseBranch "$RUN_DIR/repo.json")"
BRANCH="$(jq -r .workingBranch "$RUN_DIR/repo.json")"

cd "$REPO_PATH"

# Sanity checks
[ "$(git symbolic-ref --short HEAD)" = "$BRANCH" ] \
    || { echo "Not on $BRANCH" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] \
    || { echo "Working tree not clean. Commit or stash first." >&2; exit 1; }

# Rebase on latest base
echo "[push-and-pr] Fetching origin/$BASE_BRANCH ..." >&2
git fetch --quiet origin "$BASE_BRANCH"
if ! git rebase "origin/$BASE_BRANCH"; then
    echo "Rebase conflicts. Resolve manually and re-run." >&2
    exit 1
fi

# Push
echo "[push-and-pr] Pushing $BRANCH ..." >&2
git push -u origin "$BRANCH"

# Checkpoint C5 — target branch (no silent default)
TARGET="$(bash "$SCRIPT_DIR/aidlc.sh" ask "Target branch for PR (e.g. main, develop)" "$BASE_BRANCH")"

# PR body from prompt template (must already be rendered by deployment-agent)
PR_BODY_FILE="$RUN_DIR/pr-body.md"
if [ ! -f "$PR_BODY_FILE" ]; then
    echo "[push-and-pr] No pr-body.md found at $PR_BODY_FILE. Generating a minimal one." >&2
    cat > "$PR_BODY_FILE" <<EOF
## AIDLC run $RUN_ID

Auto-generated PR. See .aidlc/runs/$RUN_ID/ for full artifacts.

### Decisions
\`\`\`
$(cat "$RUN_DIR/decisions.log" 2>/dev/null || echo "(no decisions log)")
\`\`\`
EOF
fi

# Title from first commit on branch
TITLE="$(git log -1 --format=%s "origin/$BASE_BRANCH..HEAD" 2>/dev/null \
       || git log -1 --format=%s)"

echo "[push-and-pr] Creating PR: base=$TARGET head=$BRANCH" >&2
PR_URL=$(gh pr create \
    --base "$TARGET" \
    --head "$BRANCH" \
    --title "$TITLE" \
    --body-file "$PR_BODY_FILE" \
    2>&1) || {
    echo "$PR_URL" >&2
    echo "[push-and-pr] PR creation failed. If 422 'already exists', update existing PR manually." >&2
    exit 1
}

echo "$PR_URL"
echo "$PR_URL" > "$RUN_DIR/pr.url"
echo "[push-and-pr] Done. PR: $PR_URL" >&2
