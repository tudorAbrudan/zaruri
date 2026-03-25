#!/bin/bash
# Post-edit Swift quality check — runs automatically after every Edit/Write on .swift files.
# Receives Claude Code tool-use event as JSON on stdin.

FILE=$(python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
")

[[ "$FILE" != *.swift ]] && exit 0
[[ ! -f "$FILE" ]] && exit 0

BASENAME=$(basename "$FILE")
DIR=$(basename "$(dirname "$FILE")")
ISSUES=()

# 1. File size limits (Views ≤500, ViewModels ≤300, Models ≤200)
LINES=$(wc -l < "$FILE")
LIMIT=500
[[ "$DIR" == "ViewModels" ]] && LIMIT=300
[[ "$DIR" == "Models" ]]     && LIMIT=200
(( LINES > LIMIT )) && ISSUES+=("📏 $BASENAME: ${LINES} linii (limita ${LIMIT})")

# 2. Hardcoded Romanian strings not going through localization
HARDCODED=$(grep -nE 'Text\("[^"]*[ăîâșțĂÎÂȘȚ][^"]*"\)' "$FILE" 2>/dev/null \
    | grep -v '\.localized' | head -3)
[[ -n "$HARDCODED" ]] && ISSUES+=("🌍 Stringuri nelocalizate în $BASENAME")

# 3. Suspicious force unwrap (excludes fatalError, comments, strings)
FORCE=$(grep -nE '\w!' "$FILE" 2>/dev/null \
    | grep -vE '(fatalError|//.*!|"[^"]*![^"]*")' | head -3)
[[ -n "$FORCE" ]] && ISSUES+=("💥 Posibil force unwrap în $BASENAME")

# 4. Missing [weak self] in async closures
WEAK=$(grep -nE 'Task\s*\{|DispatchQueue\.' "$FILE" 2>/dev/null \
    | grep -v 'weak self' | grep -v '@MainActor' | head -2)
[[ -n "$WEAK" ]] && ISSUES+=("🔗 Verifică [weak self] în closures async din $BASENAME")

if (( ${#ISSUES[@]} > 0 )); then
    echo ""
    echo "┌─ Verificări automate ($BASENAME) ─────────────"
    for issue in "${ISSUES[@]}"; do
        echo "│  $issue"
    done
    echo "└───────────────────────────────────────────────"
fi

exit 0
