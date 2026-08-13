#!/bin/sh
# Vingt runs completes sans intervention. Une run qui n'atteint jamais la salle
# 10 n'est pas forcement un probleme d'equilibrage : c'est peut-etre un blocage.
# Lire les lignes, pas seulement le code de sortie.
cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:-$HOME/Téléchargements/Godot_v4.7.1-stable_linux.x86_64}"
RUNS="${RUNS:-20}"
IMAGES="${IMAGES:-220000}"   # vingt salles et leurs panneaux tiennent large dedans
ECHECS=0

for GRAINE in $(seq 1 "$RUNS"); do
    SORTIE=$("$GODOT" --headless --path . --audio-driver Dummy --fixed-fps 60 \
        --quit-after "$IMAGES" scenes/run.tscn -- --auto --mode=grimoire \
        --graine="$GRAINE" --chapitre="${CHAPITRE:-1}" 2>&1)
    if echo "$SORTIE" | grep -q "SCRIPT ERROR"; then
        echo "graine $GRAINE : SCRIPT ERROR"
        echo "$SORTIE" | grep -A3 "SCRIPT ERROR" | head -8
        ECHECS=$((ECHECS + 1))
    fi
    if echo "$SORTIE" | grep -q "^BLOCAGE"; then
        echo "graine $GRAINE : $(echo "$SORTIE" | grep '^BLOCAGE' | head -1)"
        ECHECS=$((ECHECS + 1))
    fi
    LIGNE=$(echo "$SORTIE" | grep "run terminee")
    if [ -z "$LIGNE" ]; then
        DERNIERE=$(echo "$SORTIE" | grep "^salle" | tail -1)
        echo "graine $GRAINE : BLOCAGE (aucune fin de run) — derniere trace : $DERNIERE"
        ECHECS=$((ECHECS + 1))
    else
        echo "graine $GRAINE : $LIGNE"
    fi
done

echo "Runs en echec : $ECHECS / $RUNS"
exit "$ECHECS"
