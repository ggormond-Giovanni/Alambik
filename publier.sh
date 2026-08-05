#!/bin/sh
# Produit l'APK a distribuer dans dist/, celui qu'on telecharge depuis le depot.
#
# Signature : les secrets vivent dans ~/.config/alambic/release.env, jamais dans
# le depot. Sans ce fichier, on retombe sur un APK debug — installable aussi,
# mais plus lent et marque comme tel.
#
#   ./publier.sh          version lue dans export_presets.cfg
#   ./publier.sh 0.2      force le numero de version
set -e
cd "$(dirname "$0")" || exit 1
GODOT="${GODOT:-$HOME/Téléchargements/Godot_v4.7.1-stable_linux.x86_64}"
SECRETS="$HOME/.config/alambic/release.env"

VERSION="$1"
if [ -z "$VERSION" ]; then
    VERSION=$(grep '^version/name=' export_presets.cfg | cut -d'"' -f2)
fi

MODE=release
if [ -f "$SECRETS" ]; then
    . "$SECRETS"
else
    echo "Pas de $SECRETS : signature de debug utilisee."
    MODE=debug
fi

mkdir -p dist
APK="dist/alambic-$VERSION.apk"

echo "--- verification avant publication ---"
./verifier.sh

echo "--- export $MODE ---"
if [ "$MODE" = release ]; then
    "$GODOT" --headless --path . --export-release "Android" "$APK"
else
    "$GODOT" --headless --path . --export-debug "Android" "$APK"
fi

# Le lien dist/alambic.apk pointe toujours sur la derniere version : c'est
# l'adresse stable a donner, pendant que les versions numerotees s'empilent.
cp -f "$APK" dist/alambic.apk

echo
echo "$APK  ($(du -h "$APK" | cut -f1), signature $MODE)"
echo "Copie stable : dist/alambic.apk"
