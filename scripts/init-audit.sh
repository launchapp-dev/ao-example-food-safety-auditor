#!/usr/bin/env bash
# init-audit.sh — Initialize audit run directories and validate config files
set -euo pipefail

FACILITY="${1:-main-facility}"
TODAY=$(date +%Y-%m-%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Food Safety Audit Initialization ==="
echo "Facility: $FACILITY"
echo "Date: $TODAY"
echo "Project Root: $PROJECT_ROOT"
echo ""

# Ensure output directories exist
mkdir -p "$PROJECT_ROOT/data/checklists"
mkdir -p "$PROJECT_ROOT/data/findings"
mkdir -p "$PROJECT_ROOT/data/classifications"
mkdir -p "$PROJECT_ROOT/data/capas"
mkdir -p "$PROJECT_ROOT/data/ledger"
mkdir -p "$PROJECT_ROOT/output/reports"
mkdir -p "$PROJECT_ROOT/output/certificates"

# Validate required config files
REQUIRED_FILES=(
  "config/facility-profiles/${FACILITY}.yaml"
  "config/haccp-plans/general-food-processing.yaml"
  "config/critical-limits.yaml"
  "config/audit-schedules.yaml"
  "config/capa-templates.yaml"
)

echo "Validating config files..."
for f in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$PROJECT_ROOT/$f" ]; then
    echo "ERROR: Required config file missing: $f"
    exit 1
  fi
  echo "  OK: $f"
done

# Initialize audit ledger if not present
LEDGER="$PROJECT_ROOT/data/ledger/audit-ledger.json"
if [ ! -f "$LEDGER" ]; then
  echo '{"ledger_version":"1.0","facility_id":"'"$FACILITY"'","audit_history":[],"compliance_trend":{}}' > "$LEDGER"
  echo "  Initialized audit ledger"
fi

echo ""
echo "Audit environment ready for facility: $FACILITY, date: $TODAY"
echo "Output directories confirmed."
