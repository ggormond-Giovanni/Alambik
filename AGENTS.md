# Alambik — guide des agents

Roguelite de tir portrait Android, Godot 4.7.1, GDScript.

## Démarrage à faible contexte

1. Lire ce fichier, puis `docs/INDEX.md`.
2. Lire le `AGENTS.md` le plus proche du dossier modifié.
3. Ouvrir uniquement les fichiers indiqués par l'index ou trouvés par recherche de symbole.
4. Pour un gros fichier, chercher d'abord les fonctions/classes concernées (`rg -n '^func|^class_name|^const'`) puis lire une plage ciblée. Ne pas charger le fichier entier par réflexe.

Ne pas lire par défaut : `docs/archive/`, `human/`, les `.uid`, les `.import`, les PNG, polices, audio, APK ou autres binaires. Les ouvrir uniquement si la tâche les concerne.

## Sources de vérité

- Design voulu : `docs/design/GAME_DESIGN.md`. Chercher le chapitre pertinent au lieu de tout lire.
- État de travail court : `docs/CURRENT.md`.
- Routage code → fichiers : `docs/INDEX.md` puis `scripts/INDEX.md`.
- Historique : `docs/archive/` ; consultation exceptionnelle seulement.
- `human/` est l'interface d'édition du propriétaire. Ne la lire que s'il demande de « lire human », d'appliquer ses changements ou si la tâche porte explicitement sur son contenu.

## Invariants

- Godot 4.7.1.
- Identifiants et commentaires en français sans accents ; textes joueur avec accents.
- Les commentaires expliquent pourquoi, pas ce que le code dit déjà.
- Aucune valeur d'équilibrage en dur dans la logique : utiliser `data/reglages.gd` ou les catalogues de `data/`.
- Ne reprendre aucun nom, texte, icône, sprite ou son d'un autre jeu.
- Direction artistique : `human/11_DIRECTION_ARTISTIQUE.txt` uniquement quand la tâche visuelle l'exige.
- Avec `:=`, préférer `lerpf`, `clampf`, `maxf`, `maxi`, `absf` aux fonctions renvoyant un `Variant`.
- Typer les valeurs provenant des clés de `Dictionary`.
- Ne pas modifier un tableau pendant son itération.
- Pour les blocs de salle, utiliser `Geometrie.ligne_libre` plutôt qu'un rayon lancé depuis `_process`.

## Vérification

Après modification de code ou de données :

```sh
./verifier.sh
./sondes/vingt_runs.sh
```

Lire les erreurs et le détail des runs, pas seulement le code de sortie. Une tâche documentaire seule n'exige pas les vingt runs.
