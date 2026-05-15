#!/usr/bin/env bash
# clone-and-branch.sh — stages 1 + 2 of the AIDLC flow.
# Clones the target repo and creates the working branch, with explicit checkpoints.
#
# Usage: clone-and-branch.sh <runId> <repoUrl> <kind> [ticket] [fromJava] [toJava]

set -euo pipefail

RUN_ID="${1:?runId required}"
REPO_URL="${2:?repoUrl required}"
KIND="${3:?kind required}"
TICKET="${4:-}"
FROM_JAVA="${5:-}"
TO_JAVA="${6:-}"

AIDLC_HOME="${AIDLC_HOME:-$(pwd)/.aidlc}"
RUN_DIR="$AIDLC_HOME/runs/$RUN_ID"
WORKSPACE_DIR="$AIDLC_HOME/workspace"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export AIDLC_RUN_ID="$RUN_ID"

log()   { printf '[clone-and-branch] %s\n' "$*" >&2; }
fatal() { printf '[clone-and-branch][FATAL] %s\n' "$*" >&2; exit 1; }

REPO_NAME="$(basename "$REPO_URL" .git)"
REPO_PATH="$WORKSPACE_DIR/$REPO_NAME"

# --- Stage 1: clone -----------------------------------------------------------
if [ -d "$REPO_PATH/.git" ]; then
    log "Repo already cloned at $REPO_PATH — skipping clone."
else
    log "About to clone:"
    log "  url:  $REPO_URL"
    log "  path: $REPO_PATH"
    bash "$SCRIPT_DIR/aidlc.sh" confirm "Proceed with clone?" \
        || fatal "User declined clone."
    mkdir -p "$WORKSPACE_DIR"
    git clone --depth 50 "$REPO_URL" "$REPO_PATH" \
        || fatal "git clone failed. If auth-related, configure your SSH key or PAT and retry."
fi

cd "$REPO_PATH"

# --- Determine base branch ----------------------------------------------------
BASE_BRANCH="$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}' || echo main)"
[ -z "$BASE_BRANCH" ] && BASE_BRANCH="main"

# --- Determine target branch name --------------------------------------------
case "$KIND" in
    feature|bugfix)
        [ -n "$TICKET" ] || fatal "Ticket required for kind=$KIND"
        SLUG="$(bash "$SCRIPT_DIR/aidlc.sh" ask "Short kebab title for the branch (e.g. add-search)")"
        BRANCH="aidlc/${TICKET}-${SLUG}"
        ;;
    upgrade)
        [ -n "$FROM_JAVA" ] && [ -n "$TO_JAVA" ] || fatal "from/to Java required for upgrade"
        BRANCH="aidlc/upgrade-java-${FROM_JAVA}-to-${TO_JAVA}"
        ;;
    *) fatal "Unknown kind: $KIND" ;;
esac

# --- Stage 2: branch ----------------------------------------------------------
log "Fetching origin/$BASE_BRANCH ..."
git fetch --quiet origin "$BASE_BRANCH"

if git show-ref --quiet "refs/heads/$BRANCH"; then
    log "Branch '$BRANCH' already exists locally."
    DECISION="$(bash "$SCRIPT_DIR/aidlc.sh" ask "Reuse existing branch, rename it, or abort? (reuse|rename|abort)" "abort")"
    case "$DECISION" in
        reuse) git checkout "$BRANCH" ;;
        rename) NEW="$(bash "$SCRIPT_DIR/aidlc.sh" ask "New branch name")"; git branch -m "$BRANCH" "$NEW"; BRANCH="$NEW" ;;
        *) fatal "Aborted by user." ;;
    esac
else
    bash "$SCRIPT_DIR/aidlc.sh" confirm "Create branch '$BRANCH' off 'origin/$BASE_BRANCH'?" \
        || fatal "User declined branch creation (C2)."
    git checkout -b "$BRANCH" "origin/$BASE_BRANCH"
fi

# --- Persist state ------------------------------------------------------------
mkdir -p "$RUN_DIR"
cat > "$RUN_DIR/repo.json" <<EOF
{
  "repoPath": "$REPO_PATH",
  "repoUrl": "$REPO_URL",
  "baseBranch": "$BASE_BRANCH",
  "workingBranch": "$BRANCH"
}
EOF
log "Stages 1+2 complete."
log "  repoPath:      $REPO_PATH"
log "  baseBranch:    $BASE_BRANCH"
log "  workingBranch: $BRANCH"
