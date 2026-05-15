#!/usr/bin/env bash
# AIDLC: validate the .github configuration before a run.
# Checks all required agents, prompts, scripts, and MCP env vars are present.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GH="$ROOT/.github"
ERRORS=0

check() {
  if [[ -e "$GH/$1" ]]; then
    echo "  ok    .github/$1"
  else
    echo "  MISS  .github/$1"
    ERRORS=$((ERRORS+1))
  fi
}

echo "==> Validating .github/ structure"

for f in copilot-instructions.md README.md CODEOWNERS; do check "$f"; done

echo "--- agents/"
for a in orchestrator jira-analyzer architect code-generator test-generator sonar-reviewer nexus-scanner code-reviewer deployment-agent; do
  check "agents/${a}.md"
done

echo "--- instructions/"
for i in java-style spring-boot testing security mcp-sonarqube mcp-nexus mcp-jira; do
  check "instructions/${i}.md"
done

echo "--- prompts/"
for p in generate-controller generate-service generate-entity generate-junit-test pr-body; do
  check "prompts/${p}.prompt.md"
done

echo "--- skills/"
for s in spring-boot-codegen junit-coverage sonar-integration nexus-integration jira-integration; do
  check "skills/${s}.md"
done

echo "--- workflows/"
for w in aidlc-pipeline aidlc-stage-codegen aidlc-stage-tests aidlc-stage-sonar aidlc-stage-nexus aidlc-review; do
  check "workflows/${w}.yml"
done

echo "--- scripts/"
for s in run-pipeline.sh run-stage.sh seed-jira.sh validate-config.sh; do
  check "scripts/${s}"
done

echo
echo "==> Validating MCP env vars"
for v in JIRA_BASE_URL JIRA_EMAIL JIRA_API_TOKEN SONAR_HOST_URL SONAR_TOKEN NEXUS_IQ_URL NEXUS_IQ_USER NEXUS_IQ_TOKEN; do
  if [[ -n "${!v:-}" ]]; then
    echo "  ok    $v is set"
  else
    echo "  WARN  $v is not set in the current shell"
  fi
done

echo
if [[ $ERRORS -eq 0 ]]; then
  echo "==> Validation passed."
  exit 0
else
  echo "==> Validation FAILED: $ERRORS missing file(s)."
  exit 1
fi
