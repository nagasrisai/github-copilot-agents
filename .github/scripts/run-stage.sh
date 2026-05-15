#!/usr/bin/env bash
# AIDLC: run a single pipeline stage standalone.
#
# Usage:
#   ./.github/scripts/run-stage.sh <stage> <ticket-or-pipeline-id> [--service <name>]
#
# Stages: jira | architect | codegen | tests | sonar | nexus | review | deploy

set -euo pipefail

STAGE="${1:-}"
ID="${2:-}"
if [[ -z "$STAGE" || -z "$ID" ]]; then
  echo "Usage: $0 <stage> <id> [--service <name>]" >&2
  echo "Stages: jira | architect | codegen | tests | sonar | nexus | review | deploy" >&2
  exit 1
fi

SERVICE=""
shift 2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --service) SERVICE="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

declare -A AGENT_BY_STAGE=(
  [jira]=jira-analyzer
  [architect]=architect
  [codegen]=code-generator
  [tests]=test-generator
  [sonar]=sonar-reviewer
  [nexus]=nexus-scanner
  [review]=code-reviewer
  [deploy]=deployment-agent
)

AGENT="${AGENT_BY_STAGE[$STAGE]:-}"
if [[ -z "$AGENT" ]]; then
  echo "Unknown stage: $STAGE" >&2; exit 1
fi

echo "==> AIDLC stage: $STAGE (agent: $AGENT)"
echo "    Target id: $ID  Service: ${SERVICE:-auto}"

gh copilot exec "Run stage $STAGE for $ID (service: ${SERVICE:-auto})" \
  --instructions .github/copilot-instructions.md \
  --agent ".github/agents/${AGENT}.md"
