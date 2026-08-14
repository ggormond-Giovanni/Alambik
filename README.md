# Alambic

Un roguelite de tir vue de dessus pour Android, en portrait, jouable à une main,
par sessions d'environ dix minutes.

Une alchimiste descend dans un grimoire vivant. Chaque page est une salle, les
créatures sont d'encre, de plume et de verre brisé. Les compétences de run sont
des **Améliorations** ; trois fois par chapitre, un **Alambic** génère un Élément et
le fusionne avec un Amélioration choisi. L'effet original reste actif et reçoit une
transformation beaucoup plus puissante.

Dix mondes de trois chapitres et vingt salles structurent la campagne. Une run
complète offre six Améliorations et trois Fusions élémentaires ; le chapitre suivant
s'ouvre quand le précédent est terminé.

## Modifier le jeu sans lire le code

Le dossier `human/` présente en français les valeurs et comportements du héros,
des Améliorations, des monstres, des boss, des patterns, des Maîtrises et de la
progression. Modifier ces fichiers `.txt`, puis demander à l'assistant de lire
`human` et d'appliquer les changements.

*Alambic est un nom de travail, pas encore vérifié sur les registres de marques.*

## État

Tranche verticale jouable : campagne de trente chapitres, vingt salles par run,
six Améliorations, trois Alambics élémentaires et trente Maîtrises, plus une Mine de
survie de cinq minutes et les Épreuves rituelles. Le jeu entier adopte une
direction pixel art moderne inspirée du 16-bit sur grille de quatre pixels. Les contenus que `design.txt`
laisse ouverts ne sont pas figés.

## Commandes

```sh
./lancer.sh              # jouer sur PC Linux, fenêtre au ratio d'un téléphone
./deploy.sh              # installer sur le téléphone branché (voir MOBILE.md)
./publier.sh             # produire dist/alambic.apk, signé pour distribution
./verifier.sh            # tests, SCRIPT ERROR, cohérence des données
./sondes/vingt_runs.sh   # vingt runs headless pilotées par un bot (CHAPITRE=2 pour changer)
```

Sous Windows, le raccourci **Alambic** du Bureau lance directement Godot 4.7.1
dans une fenêtre 450×800.

## Télécharger l'APK

`./publier.sh` produit l'APK de distribution. Voir `MOBILE.md`.

Arguments de développement, après `--` :

```sh
./lancer.sh -- --salle=20 --dote=6      # aller voir le boss avec six Améliorations
./lancer.sh -- --chapitre=3             # commencer au troisième chapitre
./lancer.sh -- --graine=42              # rejouer exactement la même run
./lancer.sh -- --auto --bavard          # laisser le bot jouer, en commentant
./lancer.sh -- --mode=mine              # lancer la Mine
./lancer.sh -- --mode=epreuve_sorts     # lancer les Épreuves rituelles
```

## Rendu

Le socle est dessiné par le code (`scripts/retro16.gd`, `scripts/dessin.gd`,
`scripts/palette.gd`). La direction combine pixels nets, palette fantasy riche,
volumes éclairés et effets modernes ; elle ne cherche pas à reproduire les
limitations matérielles d'une console historique.
Les effets sonores et l'ambiance du menu sont synthétisés au démarrage ; la
musique de combat est chargée depuis `assets/audio/` et se choisit dans les
Réglages. Personnages, onze ennemis et vingt boss sont animés sans planches
raster, avec des silhouettes en blocs propres à leur famille.

Le rendu ne dépend d'aucun sprite externe : il reste reproductible, recolorable
et extensible directement depuis les catalogues. Rien dans ce dépôt ne vient
d'un jeu existant.

## Structure

```
data/        équilibrage et catalogues — la seule source des chiffres
scripts/     logique et nœuds de jeu
ui/          interface, entièrement dessinée
sondes/      bot headless, cohérence des données, vingt runs
tests/       harnais maison, une suite par unité testable
```

`design.txt` est la source de vérité. `ETAT.md` dit où chercher quoi,
`AGENTS.md` liste les conventions et `JOURNAL.md` garde l'historique des
décisions.
