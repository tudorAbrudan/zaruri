#!/bin/bash
# PreToolUse guard — blocks direct edits to files that must not be hand-edited.
# Receives Claude Code tool-use event as JSON on stdin. Exit 2 = block (stderr goes to Claude).

FILE=$(python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
")

case "$FILE" in
    *.pbxproj)
        echo "Blocat: project.pbxproj nu se editează direct (risc de corupere). Modifică proiectul din Xcode." >&2
        exit 2 ;;
    */ExportOptions.plist)
        echo "Blocat: ExportOptions.plist e configurație de release. Cere confirmare explicită de la user." >&2
        exit 2 ;;
    */Localizable.strings)
        echo "Blocat: adaugă chei noi cu /localize, ca toate limbile să rămână sincronizate." >&2
        exit 2 ;;
esac
exit 0
