# Alambic

Un roguelite de tir vue de dessus pour Android, en portrait, jouable à une main,
par sessions de cinq à sept minutes.

Une alchimiste descend dans un grimoire vivant. Chaque page est une salle, les
créatures sont d'encre, de plume et de verre brisé. Les compétences sont des
**réactifs** ; quatre fois par chapitre, un **alambic** en fond deux en une
**essence** qu'aucun tirage ne donne — les deux composants sont consommés, et
l'essence vaut toujours mieux que ce qu'elle coûte. Sacrifier deux effets
connus contre un effet plus fort, c'est la décision qui porte le jeu.

Trois chapitres de cinquante pages, chacun avec son boss, son mi-chapitre et sa
propre montée en difficulté. Un chapitre s'ouvre quand le précédent est terminé.

*Alambic est un nom de travail, pas encore vérifié sur les registres de marques.*

## État

Jouable de bout en bout : trois chapitres de cinquante pages, quatre alambics et
un mi-chapitre par chapitre, quinze réactifs, dix fusions. L'équilibrage est
mesuré, pas estimé — voir `ETAT.md` et `sondes/equilibrage.gd`.

## Commandes

```sh
./lancer.sh              # jouer sur PC, fenêtre au ratio d'un téléphone
./deploy.sh              # installer sur le téléphone branché (voir MOBILE.md)
./publier.sh             # produire dist/alambic.apk, signé pour distribution
./verifier.sh            # tests, SCRIPT ERROR, cohérence des données
./sondes/vingt_runs.sh   # vingt runs headless pilotées par un bot (CHAPITRE=2 pour changer)
```

Un raccourci **Alambic** est posé sur le bureau et dans le menu des
applications ; il lance `lancer.sh`.

## Télécharger l'APK

`dist/alambic.apk` est suivi par git : depuis le téléphone, ouvrir le dépôt et
télécharger ce fichier suffit à installer le jeu. Voir `MOBILE.md`.

Arguments de développement, après `--` :

```sh
./lancer.sh -- --salle=50 --dote=12     # aller voir le boss avec douze réactifs
./lancer.sh -- --chapitre=3             # commencer au troisième chapitre
./lancer.sh -- --graine=42              # rejouer exactement la même run
./lancer.sh -- --auto --bavard          # laisser le bot jouer, en commentant
```

## Rendu

Le socle est dessiné par le code (`scripts/dessin.gd`, `scripts/palette.gd`) et
le son, musique adaptative comprise, est synthétisé au démarrage
(`autoload/sons.gd`) : aucun fichier audio dans le dépôt. Les personnages sont
animés par les planches de `assets/characters/sheets/`.

Attention à la règle du plan — le repli géométrique doit rester possible : un
`preload` sur un PNG absent casse le lancement, alors que le dessin, lui, ne
manque jamais. Rien dans ce dépôt ne vient d'un jeu existant.

## Structure

```
data/        équilibrage et catalogues — la seule source des chiffres
scripts/     logique et nœuds de jeu
ui/          interface, entièrement dessinée
sondes/      bot headless, cohérence des données, vingt runs
tests/       harnais maison, une suite par unité testable
docs/        spécification de conception et plan d'implémentation
```

Pour voir l'équilibrage chiffré — fusions contre leurs composants, écart entre
mains, course entre le héros et les créatures sur un chapitre :

```sh
~/Téléchargements/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script sondes/equilibrage.gd
```

`ETAT.md` dit où chercher quoi. `CLAUDE.md` liste les conventions.
`JOURNAL.md` garde l'historique des décisions.
