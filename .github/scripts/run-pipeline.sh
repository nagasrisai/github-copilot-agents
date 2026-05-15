#!/usr/bin/env bash
# AIDLC: run the full pipeline for a single Jira ticket via Copilot CLI.
#
# Usage:
#   ./.github/scripts/run-pipeline.sh PROJ-1234 [--microservice order-service] [--skip sonar,nexus]
#
# Requires: gh CLI, gh-copilot extension, configured MCP servers (see .github/instructions/).

set -euo pipefail

TICKET="${1:-}"
if [[ -z "$TICKET" ]]; then
  echo "Usage: $0 <JIRA_TICKET_KEY> [--microservice <name>] [--skip <stage,stage>]" >&2
  exit 1
fi

MICROSERVICE=""
SKIP=""
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --microservice) MICROSERVICE="$2"; shift 2;;
    --skip)         SKIP="$2"; shift 2;;
    *)              echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-${TICKET}"
RUN_DIR=".aidlc/runs/${RUN_ID}"
mkdir -p "$RUN_DIR"

echo "==> AIDLC run started"
echo "    Ticket:        $TICKET"
echo "    Microservice:  ${MICROSERVICE:-auto-detect}"
echo "    Skip stages:   ${SKIP:-none}"
echo "    Run dir:       $RUN_DIR"
echo

PAYLOAD=$(jq -n \
  --arg t "$TICKET" \
  --arg m "$MICROSERVICE" \
  --arg s "$SKIP" \
  '{ticketKey:$t, microservice:$m, options:{skipStages:($s|split(","))}}')

gh copilot exec "Run the AIDLC orchestrator agent with this input: $PAYLOAD" \
  --instructions .github/copilot-instructions.md \
  --agent .github/agents/orchestrator.md \
  | tee "$RUN_DIR/orchestrator.log"

echo
echo "==> AIDLC run complete: $RUN_ID"
