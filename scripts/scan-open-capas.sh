#!/usr/bin/env bash
# scan-open-capas.sh — Scan for open CAPAs past their deadline
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TODAY=$(date +%Y-%m-%d)

echo "=== CAPA Follow-Up Scan ==="
echo "Scan date: $TODAY"
echo ""

CAPA_DIR="$PROJECT_ROOT/data/capas"
mkdir -p "$CAPA_DIR"

# Find all CAPA files
CAPA_FILES=$(find "$CAPA_DIR" -name "capa-*.json" -not -name "capa-status-*" 2>/dev/null || true)

if [ -z "$CAPA_FILES" ]; then
  echo "No CAPA files found. Nothing to review."
  echo '{"scan_date":"'"$TODAY"'","open_capas":[],"overdue_capas":[],"message":"No CAPAs found"}' \
    > "$CAPA_DIR/capa-status-${TODAY}.json"
  exit 0
fi

echo "CAPA files found:"
for f in $CAPA_FILES; do
  echo "  $f"
done

echo ""
echo "Writing status summary to: $CAPA_DIR/capa-status-${TODAY}.json"
echo "Agent will read CAPA files and determine status for each open item."

# Create a scan manifest for the agent
echo '{
  "scan_date": "'"$TODAY"'",
  "capa_files_found": '"$(echo "$CAPA_FILES" | wc -l | tr -d ' ')"',
  "message": "Scan complete — agent should read each CAPA file and determine open/overdue/closed status"
}' > "$CAPA_DIR/capa-scan-manifest-${TODAY}.json"
