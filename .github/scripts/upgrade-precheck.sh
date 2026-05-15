#!/usr/bin/env bash
# upgrade-precheck.sh — verifies the local toolchain can perform the requested upgrade.
#
# Usage: upgrade-precheck.sh <fromJava> <toJava> <fromSB> <toSB>

set -euo pipefail

FROM_JAVA="${1:?fromJava required}"
TO_JAVA="${2:?toJava required}"
FROM_SB="${3:?fromSB required}"
TO_SB="${4:?toSB required}"

log()   { printf '[upgrade-precheck] %s\n' "$*" >&2; }
fatal() { printf '[upgrade-precheck][FATAL] %s\n' "$*" >&2; exit 1; }

# Java toolchain check
CURRENT_JAVA="$(java -version 2>&1 | head -n 1 | awk -F'"' '{print $2}' | cut -d. -f1)"
log "Current java -version major: $CURRENT_JAVA"
if [ "$CURRENT_JAVA" != "$TO_JAVA" ]; then
    fatal "Target Java $TO_JAVA not active. Switch JDK before upgrading."
fi

# Maven offline availability
log "Verifying Maven offline mode ..."
mvn -o -B -q --version >/dev/null || fatal "Maven not available offline."

# Spring Boot target version present in local repo
SB_JAR="$HOME/.m2/repository/org/springframework/boot/spring-boot/$TO_SB/spring-boot-$TO_SB.jar"
if [ ! -f "$SB_JAR" ]; then
    fatal "Spring Boot $TO_SB not in local Maven repo: $SB_JAR
Run 'mvn dependency:get -Dartifact=org.springframework.boot:spring-boot:$TO_SB' on an online machine first."
fi

# Detect path coverage in playbook
PLAYBOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/instructions/upgrade-playbook.md"
[ -f "$PLAYBOOK" ] || fatal "Upgrade playbook missing: $PLAYBOOK"

# Crude matrix check (the playbook lists supported jumps)
if ! grep -q "Java $FROM_JAVA . Java $TO_JAVA\|$FROM_JAVA → $TO_JAVA" "$PLAYBOOK"; then
    log "WARNING: Java $FROM_JAVA -> $TO_JAVA not explicitly listed. Proceed only if confident."
fi
if ! grep -q "$FROM_SB.*$TO_SB\|$TO_SB" "$PLAYBOOK"; then
    log "WARNING: Spring Boot $FROM_SB -> $TO_SB not explicitly listed."
fi

log "Precheck OK."
log "  Java:        $FROM_JAVA -> $TO_JAVA"
log "  Spring Boot: $FROM_SB -> $TO_SB"
log "  Playbook:    $PLAYBOOK"
