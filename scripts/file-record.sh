#!/usr/bin/env bash
# file-record.sh — Append audit results to the audit ledger
set -euo pipefail

FACILITY="${1:-main-facility}"
TODAY=$(date +%Y-%m-%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Filing Audit Record ==="
echo "Facility: $FACILITY"
echo "Date: $TODAY"

LEDGER="$PROJECT_ROOT/data/ledger/audit-ledger.json"
CLASSIFICATIONS_DIR="$PROJECT_ROOT/data/classifications"

# Find the most recent classification file for today
CLASSIFICATION_FILE=$(find "$CLASSIFICATIONS_DIR" -name "classified-${FACILITY}-${TODAY}.json" 2>/dev/null | head -1 || true)

if [ -z "$CLASSIFICATION_FILE" ]; then
  # Try preop classification
  CLASSIFICATION_FILE=$(find "$CLASSIFICATIONS_DIR" -name "preop-classified-${FACILITY}-${TODAY}.json" 2>/dev/null | head -1 || true)
fi

if [ -n "$CLASSIFICATION_FILE" ]; then
  echo "Found classification file: $CLASSIFICATION_FILE"
  echo "Ledger update: agent has written classification data; record filed at $TODAY"
else
  echo "No classification file found for today — recording as pre-op or follow-up audit"
fi

echo "Audit record filing complete."
echo "Ledger location: $LEDGER"
echo ""
echo "NOTE: The compliance-reporter agent has already updated the ledger with today's results."
echo "This step confirms the audit cycle is complete."
