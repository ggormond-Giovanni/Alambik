#!/bin/sh
# Le code de sortie des tests ne suffit pas : une erreur de compilation dans un
# script qu'aucune suite ne sollicite laisse le harnais vert. On greppe donc
# SCRIPT ERROR en plus, et on lance la sonde de coherence des donnees.
cd "$(dirname "$0")" || exit 1
GODOT="${GODOT:-$HOME/Téléchargements/Godot_v4.7.1-stable_linux.x86_64}"
SORTIE=$(mktemp)

# Le cache des classes globales vient du scan du projet : sans lui, un script
# fraichement cree n'est pas resolu et le harnais echoue a tort.
"$GODOT" --headless --path . --import >/dev/null 2>&1

"$GODOT" --headless --path . --script tests/lanceur.gd >"$SORTIE" 2>&1
CODE=$?
cat "$SORTIE"

if grep -q "SCRIPT ERROR\|SCRIPT ERROR:" "$SORTIE"; then
    echo "ECHEC : des SCRIPT ERROR sont apparus."
    rm -f "$SORTIE"
    exit 1
fi
rm -f "$SORTIE"
[ "$CODE" -ne 0 ] && exit "$CODE"

SORTIE=$(mktemp)
"$GODOT" --headless --path . --script sondes/selftest.gd >"$SORTIE" 2>&1
CODE=$?
grep -v "^$" "$SORTIE"
if grep -q "SCRIPT ERROR" "$SORTIE"; then
    echo "ECHEC : SCRIPT ERROR dans la sonde de coherence."
    rm -f "$SORTIE"
    exit 1
fi
rm -f "$SORTIE"
exit "$CODE"
