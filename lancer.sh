#!/bin/sh
# Boucle rapide : fenetre au ratio du telephone, souris emulant le doigt.
# Arguments utiles : ./lancer.sh -- --salle=10 --graine=42
cd "$(dirname "$0")" || exit 1
GODOT="${GODOT:-$HOME/Téléchargements/Godot_v4.7.1-stable_linux.x86_64}"
exec "$GODOT" --path . --resolution 450x800 "$@"
