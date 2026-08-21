# Alambik

Roguelite de tir vue de dessus pour Android, en portrait et jouable à une main. Une alchimiste descend dans un grimoire vivant ; les Améliorations acquises pendant une run peuvent être transformées par les Éléménts d'un Alambic.

Le projet est sous Godot 4.7.1 / GDScript.

## Commencer ici

Pour comprendre le dépôt sans charger des dizaines de fichiers :

- `AGENTS.md` — règles de travail pour les agents et développeurs.
- `docs/INDEX.md` — quel fichier ouvrir pour quelle tâche.
- `docs/CURRENT.md` — état de travail court.
- `docs/design/GAME_DESIGN.md` — design complet, à consulter par section.
- `scripts/INDEX.md` — carte de la logique de jeu.

Les anciens journaux et états détaillés sont conservés dans `docs/archive/` mais ne font pas partie du contexte normal de travail.

## Structure

```text
autoload/    état global, préférences, audio et écran
data/        équilibrage et catalogues
scripts/     logique, rangée par domaine
scenes/      petites scènes Godot qui branchent les scripts
ui/          interface de jeu
assets/      images, audio et polices
human/       interface d'édition humaine du design
tests/       tests déterministes
sondes/      simulations et contrôles headless
docs/        index, design, état courant, opérations, archives
```

Les valeurs de gameplay vivent dans `data/`; la logique ne doit pas les dupliquer.

## Commandes

```sh
./lancer.sh
./verifier.sh
./sondes/vingt_runs.sh
./deploy.sh
./publier.sh
```

Arguments de développement après `--` : `--salle=N`, `--chapitre=N`, `--graine=N`, `--dote=N`, `--auto`, `--bavard`, `--mode=mine`, `--mode=epreuve_sorts`.

Le guide téléphone est dans `docs/ops/MOBILE.md`.

*Alambic est un nom de travail, pas encore vérifié sur les registres de marques.*
