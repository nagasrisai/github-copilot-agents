#!/usr/bin/env bash
# aidlc.sh — master interactive driver for the AIDLC pipeline.
#
# Subcommands:
#   start            run a new pipeline end-to-end
#   resume <runId>   resume an interrupted run
#   confirm <msg>    yes/no checkpoint (default: No). Used by other scripts.
#   ask <msg> [def]  free-text prompt. Used by other scripts.
#   bootstrap        one-time setup (offline Maven repo, MCP binaries check)
#
# All prompts read from /dev/tty and write to stderr so pipelines stay clean.

set -euo pipefail

AIDLC_HOME="${AIDLC_HOME:-$(pwd)/.aidlc}"
RUNS_DIR="$AIDLC_HOME/runs"
WORKSPACE_DIR="$AIDLC_HOME/workspace"
CONFIG_FILE="$AIDLC_HOME/config.env"

# shellcheck disable=SC1090
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

log()   { printf '[aidlc] %s\n' "$*" >&2; }
fatal() { printf '[aidlc][FATAL] %s\n' "$*" >&2; exit 1; }

cmd_confirm() {
    local msg="${1:-Proceed?}"
    local answer=""
    printf '%s [y/N]: ' "$msg" > /dev/tty
    read -r answer < /dev/tty || answer=""
    record_decision "$msg" "$answer"
    case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
        y|yes) return 0 ;;
        force) printf 'FORCE\n'; return 0 ;;
        *) return 1 ;;
    esac
}

cmd_ask() {
    local msg="${1:-Answer?}"
    local default="${2:-}"
    local answer=""
    if [ -n "$default" ]; then
        printf '%s (default: %s): ' "$msg" "$default" > /dev/tty
    else
        printf '%s: ' "$msg" > /dev/tty
    fi
    read -r answer < /dev/tty || answer=""
    [ -z "$answer" ] && answer="$default"
    [ -z "$answer" ] && fatal "An answer is required."
    record_decision "$msg" "$answer"
    printf '%s\n' "$answer"
}

record_decision() {
    local q="$1" a="$2"
    local run_id="${AIDLC_RUN_ID:-_global}"
    local log_dir="$RUNS_DIR/$run_id"
    mkdir -p "$log_dir"
    printf '%s\t%s\t-> %s\n' "$(date -u +%FT%TZ)" "$q" "$a" >> "$log_dir/decisions.log"
}

new_run_id() {
    local date_part
    date_part="$(date -u +%Y-%m-%d)"
    local n=1
    while [ -d "$RUNS_DIR/run-$date_part-$(printf '%03d' "$n")" ]; do
        n=$((n + 1))
    done
    printf 'run-%s-%03d\n' "$date_part" "$n"
}

cmd_bootstrap() {
    log "Bootstrapping AIDLC..."
    mkdir -p "$RUNS_DIR" "$WORKSPACE_DIR"
    [ -f "$CONFIG_FILE" ] || cat > "$CONFIG_FILE" <<'EOF'
# AIDLC config. Edit before running.
SONARQUBE_URL=http://localhost:9000
NEXUS_IQ_URL=http://localhost:8070
JIRA_URL=http://localhost:8080
EOF
    log "Pre-flight checks:"
    for bin in git java mvn gh jq; do
        if command -v "$bin" >/dev/null 2>&1; then
            log "  OK     $bin -> $(command -v "$bin")"
        else
            log "  MISSING $bin"
        fi
    done
    log "Done. Edit $CONFIG_FILE and re-run."
}

cmd_start() {
    mkdir -p "$RUNS_DIR" "$WORKSPACE_DIR"
    local kind ticket upgrade_from upgrade_to repo_url run_id

    kind=$("$0" ask "Run kind (feature|bugfix|upgrade)" "feature")
    case "$kind" in
        feature|bugfix) ticket=$("$0" ask "Jira ticket key (e.g. PROJ-1234)") ;;
        upgrade)
            upgrade_from=$("$0" ask "Current Java version (e.g. 17)")
            upgrade_to=$("$0" ask "Target Java version (e.g. 21)")
            upgrade_sb_to=$("$0" ask "Target Spring Boot version (e.g. 3.3.5)")
            ;;
        *) fatal "Unknown kind: $kind" ;;
    esac

    repo_url=$("$0" ask "Git URL of the target repository")

    run_id=$(new_run_id)
    export AIDLC_RUN_ID="$run_id"
    local run_dir="$RUNS_DIR/$run_id"
    mkdir -p "$run_dir/scans"

    cat > "$run_dir/context.json" <<EOF
{
  "runId": "$run_id",
  "kind": "$kind",
  "ticket": "${ticket:-}",
  "upgradeFromJava": "${upgrade_from:-}",
  "upgradeToJava": "${upgrade_to:-}",
  "upgradeToSpringBoot": "${upgrade_sb_to:-}",
  "repoUrl": "$repo_url"
}
EOF
    log "Run started: $run_id"
    log "Context written: $run_dir/context.json"

    # C1
    "$0" confirm "Run AIDLC ($kind) on '${ticket:-$upgrade_from->$upgrade_to}'?" \
        || fatal "User declined at C1."

    # Stages 1+2
    bash "$(dirname "$0")/clone-and-branch.sh" "$run_id" "$repo_url" "$kind" "${ticket:-}" "${upgrade_from:-}" "${upgrade_to:-}"

    log "Stages 3-7 are agent-driven. Invoke the orchestrator agent with runId=$run_id."
    log "When all checks pass, the orchestrator will call:"
    log "  bash $(dirname "$0")/request-review.sh $run_id    # checkpoint C4"
    log "  bash $(dirname "$0")/push-and-pr.sh   $run_id    # checkpoint C5 + push + PR"
}

cmd_resume() {
    local run_id="${1:-}"
    [ -n "$run_id" ] || fatal "Usage: aidlc.sh resume <runId>"
    [ -d "$RUNS_DIR/$run_id" ] || fatal "No such run: $run_id"
    export AIDLC_RUN_ID="$run_id"
    log "Resuming $run_id. Inspect $RUNS_DIR/$run_id/manifest.json for last completed stage."
    log "Hand off to the orchestrator agent with runId=$run_id and resume=true."
}

main() {
    local sub="${1:-}"
    shift || true
    case "$sub" in
        confirm)   cmd_confirm "$@" ;;
        ask)       cmd_ask "$@" ;;
        bootstrap) cmd_bootstrap "$@" ;;
        start)     cmd_start "$@" ;;
        resume)    cmd_resume "$@" ;;
        ""|help|-h|--help)
            cat <<EOF
aidlc.sh — AIDLC pipeline driver

Usage:
  aidlc.sh bootstrap                  one-time setup
  aidlc.sh start                      start a new run (interactive)
  aidlc.sh resume <runId>             resume an interrupted run
  aidlc.sh confirm "<message>"        yes/no checkpoint (used by other scripts)
  aidlc.sh ask "<message>" [default]  free-text prompt (used by other scripts)
EOF
            ;;
        *) fatal "Unknown subcommand: $sub. Run 'aidlc.sh help'." ;;
    esac
}

main "$@"
