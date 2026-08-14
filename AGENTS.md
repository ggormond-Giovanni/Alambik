# Alambic — conventions du dépôt

Roguelite de tir en vue du dessus, portrait, Android. Godot 4.7.1, GDScript.
`design.txt` est la source de vérité, `ETAT.md` décrit l'état courant et
`JOURNAL.md` conserve l'historique des décisions.

Le dossier `human/` est l'interface d'édition du propriétaire du projet. Quand
il demande de « lire human » ou d'appliquer ses changements, lire tous ses
fichiers `.txt`, comparer les entrées marquées à modifier avec les données du
jeu, puis répercuter les décisions dans le code. Ne jamais écraser une idée
humaine lors d'une synchronisation depuis le code.

## Règles du projet

- Utiliser Godot 4.7.1. Sous Windows, l'exécutable local est
  `C:\Users\giova\Documents\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe`.
- Écrire les identifiants et commentaires en français sans accents. Les textes
  affichés au joueur gardent leurs accents.
- Les commentaires expliquent pourquoi, pas ce que le code fait déjà.
- Ne mettre aucune valeur d'équilibrage en dur dans la logique. Les valeurs
  vivent dans `data/reglages.gd` ou dans les catalogues de `data/`.
- Après une modification, lancer la vérification complète et contrôler aussi
  l'absence de `SCRIPT ERROR`.
- Ne publier aucun chiffre de performance ou d'équilibrage sans mesure.
- Ne reprendre aucun nom, texte, icône, sprite ou son d'un autre jeu.
- Suivre `human/11_DIRECTION_ARTISTIQUE.txt` : pixel art moderne fantasy,
  grille de quatre pixels, silhouettes lisibles, profondeur et VFX contemporains.

## Pièges GDScript connus

- Avec une inférence `:=`, préférer `lerpf`, `clampf`, `maxf`, `maxi` et `absf`
  aux fonctions qui renvoient un `Variant`.
- Typer explicitement les valeurs provenant des clés de `Dictionary`.
- Ne jamais modifier un tableau pendant son itération ; le parcourir à rebours.
- Une erreur d'exécution interrompt aussi les fonctions appelantes. Le lanceur
  de tests possède une sécurité pour éviter un processus silencieux.
- Pour les blocs de salle, utiliser `Geometrie.ligne_libre` plutôt qu'une
  requête de rayon lancée depuis `_process`.

## Boucles de travail

- PC Windows : le raccourci `Alambic` du Bureau lance le jeu en 450×800 avec
  émulation tactile par la souris.
- Linux : `./lancer.sh` lance la même boucle rapide.
- Téléphone : `./deploy.sh` exporte et installe l'APK lorsque le SDK Android,
  ADB et les templates Godot sont configurés.
- Vérification : `./verifier.sh`, puis `./sondes/vingt_runs.sh`. Toujours lire
  le détail des runs, pas seulement le code de sortie.
