# Alambic

Un roguelite de tir vue de dessus pour Android, en portrait, jouable à une main,
par sessions de cinq à sept minutes.

Une alchimiste descend dans un grimoire vivant. Chaque page est une salle, les
créatures sont d'encre, de plume et de verre brisé. Les compétences sont des
**réactifs** ; aux pages 5 et 9, un **alambic** permet d'en fondre deux en une
**essence** qu'aucun tirage ne donne. Sacrifier deux effets connus contre un
effet plus fort, c'est la décision qui porte le jeu.

*Alambic est un nom de travail, pas encore vérifié sur les registres de marques.*

## État

V1 jouable de bout en bout : dix pages, deux alambics, un boss, quinze réactifs,
dix fusions. Voir `ETAT.md` pour ce qui est mesuré et ce qui ne l'est pas.

## Commandes

```sh
./lancer.sh              # jouer sur PC, fenêtre au ratio d'un téléphone
./deploy.sh              # installer sur le téléphone branché (voir MOBILE.md)
./publier.sh             # produire dist/alambic.apk, signé pour distribution
./verifier.sh            # tests, SCRIPT ERROR, cohérence des données
./sondes/vingt_runs.sh   # vingt runs headless pilotées par un bot
```

Un raccourci **Alambic** est posé sur le bureau et dans le menu des
applications ; il lance `lancer.sh`.

## Télécharger l'APK

`dist/alambic.apk` est suivi par git : depuis le téléphone, ouvrir le dépôt et
télécharger ce fichier suffit à installer le jeu. Voir `MOBILE.md`.

Arguments de développement, après `--` :

```sh
./lancer.sh -- --salle=10 --dote=7      # aller voir le boss avec sept réactifs
./lancer.sh -- --graine=42              # rejouer exactement la même run
./lancer.sh -- --auto --bavard          # laisser le bot jouer, en commentant
```

## Rendu

Le socle est dessiné par le code (`scripts/dessin.gd`, `scripts/palette.gd`) et
le son est synthétisé au démarrage (`autoload/sons.gd`) : aucun fichier audio
dans le dépôt. Des sprites de personnages ont été ajoutés depuis dans
`assets/characters/` et sont utilisés par le héros et les ennemis.

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

`ETAT.md` dit où chercher quoi. `CLAUDE.md` liste les conventions.
`JOURNAL.md` garde l'historique des décisions.
