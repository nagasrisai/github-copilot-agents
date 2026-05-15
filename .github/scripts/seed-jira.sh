#!/usr/bin/env bash
# AIDLC: seed example Jira-style tickets into a local fixtures file
# for offline / demo runs of the pipeline.
#
# Usage:
#   ./.github/scripts/seed-jira.sh [output-file]
#
# Default output: .aidlc/fixtures/jira-tickets.json

set -euo pipefail

OUT="${1:-.aidlc/fixtures/jira-tickets.json}"
mkdir -p "$(dirname "$OUT")"

cat > "$OUT" <<'EOF'
[
  {
    "ticketKey": "PROJ-1001",
    "title": "Add order creation endpoint with idempotency key",
    "type": "story",
    "priority": "high",
    "description": "As a customer I want to create orders idempotently so that retries do not duplicate charges.",
    "acceptanceCriteria": [
      "POST /api/orders accepts an Idempotency-Key header",
      "Duplicate requests within 24h return the original response",
      "Request body validated; 400 on invalid amount or missing customerId"
    ],
    "storyPoints": 5,
    "microservice": "order-service"
  },
  {
    "ticketKey": "PROJ-1002",
    "title": "Bulk-import products from CSV",
    "type": "story",
    "priority": "medium",
    "description": "Support import of up to 10k products in a single CSV upload with per-row validation reporting.",
    "acceptanceCriteria": [
      "POST /api/products/import accepts multipart CSV",
      "Per-row errors returned in response",
      "Successful rows are persisted even if some fail"
    ],
    "storyPoints": 8,
    "microservice": "product-service"
  },
  {
    "ticketKey": "PROJ-1003",
    "title": "Add JWT-based service-to-service auth",
    "type": "task",
    "priority": "highest",
    "description": "Standardize JWT-based S2S auth across payment-service and order-service.",
    "acceptanceCriteria": [
      "Both services accept signed JWTs from issuer auth-service",
      "Token claims include serviceName and scopes",
      "Unauthorized requests return 401 with structured error"
    ],
    "storyPoints": 3,
    "microservice": "payment-service"
  }
]
EOF

echo "Wrote $(jq length < "$OUT") tickets to $OUT"
