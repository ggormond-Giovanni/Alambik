#!/bin/sh
# Boucle de verite : ce que le PC ne peut pas dire (confort du pouce, lisibilite
# au soleil, images par seconde reelles, safe area). Export APK, installation,
# lancement, puis logcat filtre.
#
#   ./deploy.sh              exporte, installe, lance, suit les logs
#   ./deploy.sh --sans-logs  s'arrete apres le lancement
set -e
cd "$(dirname "$0")" || exit 1
GODOT="${GODOT:-$HOME/Téléchargements/Godot_v4.7.1-stable_linux.x86_64}"
ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"
PAQUET="com.giovanni.alambic"

if ! "$ADB" get-state >/dev/null 2>&1; then
    echo "Aucun appareil visible par adb."
    echo "  USB      : brancher le cable, autoriser le debogage sur le telephone."
    echo "  Sans fil : adb pair <ip>:<port>  puis  adb connect <ip>:<port>"
    "$ADB" devices
    exit 1
fi

mkdir -p build
echo "--- export APK debug ---"
"$GODOT" --headless --path . --export-debug "Android" build/alambic.apk

echo "--- installation ---"
"$ADB" install -r build/alambic.apk

echo "--- lancement ---"
"$ADB" shell monkey -p "$PAQUET" -c android.intent.category.LAUNCHER 1 >/dev/null

[ "$1" = "--sans-logs" ] && exit 0

"$ADB" logcat -c
echo "--- logcat (Ctrl-C pour sortir) ---"
"$ADB" logcat godot:V GodotEngine:V "*:S"
