#!/usr/bin/env bash
# request-review.sh — stage 8 (human review) of the AIDLC flow.
# Presents a summary + optional full diff and gates the push on checkpoint C4.
#
# Usage: request-review.sh <runId>

set -euo pipefail

RUN_ID="${1:?runId required}"
AIDLC_HOME="${AIDLC_HOME:-$(pwd)/.aidlc}"
RUN_DIR="$AIDLC_HOME/runs/$RUN_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AIDLC_RUN_ID="$RUN_ID"

[ -d "$RUN_DIR" ] || { echo "No such run: $RUN_ID" >&2; exit 1; }

REPO_PATH="$(jq -r .repoPath "$RUN_DIR/repo.json")"
BASE_BRANCH="$(jq -r .baseBranch "$RUN_DIR/repo.json")"
BRANCH="$(jq -r .workingBranch "$RUN_DIR/repo.json")"

cd "$REPO_PATH"

cat >&2 <<EOF

============================================================================
 AIDLC Review Summary — run $RUN_ID
 Branch: $BRANCH   Base: $BASE_BRANCH
============================================================================
EOF

# Change stats
echo >&2
echo "  Changed files:" >&2
git diff --stat "origin/$BASE_BRANCH...HEAD" | sed 's/^/    /' >&2

# Commit list
echo >&2
echo "  Commits on branch:" >&2
git log --oneline "origin/$BASE_BRANCH..HEAD" | sed 's/^/    /' >&2

# Coverage
if [ -f "$RUN_DIR/scans/coverage.txt" ]; then
    echo >&2
    echo "  Test coverage:" >&2
    sed 's/^/    /' "$RUN_DIR/scans/coverage.txt" >&2
fi

# Sonar gate
if [ -f "$RUN_DIR/scans/sonar.json" ]; then
    GATE=$(jq -r '.qualityGate.status // "UNKNOWN"' "$RUN_DIR/scans/sonar.json")
    echo >&2
    echo "  SonarQube quality gate: $GATE" >&2
fi

# Nexus
if [ -f "$RUN_DIR/scans/nexus.json" ]; then
    CRIT=$(jq -r '[.policyViolations[]? | select(.policyThreatLevel >= 8)] | length' "$RUN_DIR/scans/nexus.json")
    echo >&2
    echo "  Nexus IQ critical violations: $CRIT" >&2
fi

# AI review
if [ -f "$RUN_DIR/scans/review.md" ]; then
    echo >&2
    echo "  AI review (top 10 lines):" >&2
    head -n 10 "$RUN_DIR/scans/review.md" | sed 's/^/    /' >&2
fi

echo >&2
echo "============================================================================" >&2

# Offer full diff
if bash "$SCRIPT_DIR/aidlc.sh" confirm "Show full diff?"; then
    git --no-pager diff "origin/$BASE_BRANCH...HEAD" >&2
fi

# Checkpoint C4
if bash "$SCRIPT_DIR/aidlc.sh" confirm "Approve and push?"; then
    echo "approved" > "$RUN_DIR/review.status"
    exit 0
fi

REASON="$(bash "$SCRIPT_DIR/aidlc.sh" ask "Reason for rejection (free text)")"
echo "rejected" > "$RUN_DIR/review.status"
echo "$REASON" > "$RUN_DIR/review.rejection"
echo "[request-review] User rejected at C4. Loop back to code-generator with this reason as new input." >&2
exit 2
