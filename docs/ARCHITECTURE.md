# Architecture d'Alambik

## Objectif

Le dépôt est organisé pour qu'une tâche locale ait un contexte local. Un humain ou une IA doit pouvoir identifier le bon domaine avant d'ouvrir du code.

La règle centrale est : **un dossier = une responsabilité identifiable ; un document = une fonction documentaire**.

## Couches

```text
project.godot
├── autoload/          état global et services persistants
├── data/              données et équilibrage
├── scripts/
│   ├── run/           orchestration d'une tentative
│   ├── acteurs/       héros, ennemis, boss, IA
│   ├── combat/        tirs, ciblage, statistiques
│   ├── monde/         salle et géométrie
│   ├── ameliorations/ logique des Améliorations
│   ├── presentation/  dessin, palette, styles
│   ├── entrees/       tactile, balayage, joystick
│   ├── menu/          contrôleur de l'accueil
│   └── dev/           outils de développement
├── scenes/            assemblage Godot minimal
├── ui/                écrans et contrôles
├── tests/             vérification déterministe
└── sondes/            simulation intégrée
```

Quelques petits scripts restent temporairement à la racine de `scripts/` car `run.gd` les charge directement par chemin (`fond.gd`, `effets.gd`, `cadre_retro.gd`, `voile_transition.gd`). Les déplacer n'apporterait presque aucun gain et imposerait une modification du gros orchestrateur ; ils pourront être absorbés lors du futur découpage de celui-ci.

## Dépendances

- `data/` ne dépend pas de l'UI.
- Les nombres d'équilibrage viennent de `data/`, jamais d'une copie dans la logique.
- `ui/` affiche et déclenche ; la logique de combat reste dans `scripts/`.
- `scenes/` reste mince : nœuds, collisions, script attaché.
- `autoload/` est réservé à l'état ou aux services réellement globaux.
- `tests/` et `sondes/` peuvent connaître le jeu ; le jeu normal ne doit pas dépendre des tests.

## Budget de contexte

La documentation est en trois températures :

1. **Chaude** — `AGENTS.md`, `docs/INDEX.md`, `docs/CURRENT.md`. Courte et fréquemment utile.
2. **Tiède** — design et guides spécialisés. À ouvrir par section lorsque la tâche l'exige.
3. **Froide** — `docs/archive/`. Historique conservé mais exclu du travail courant.

Les fichiers générés (`*.uid`, `*.import`) et les binaires ne doivent pas être lus pour comprendre le code.

## Gros fichiers

Un gros fichier n'est pas automatiquement mauvais. Il devient coûteux lorsqu'il faut tout lire pour une petite modification. La priorité est donc d'abord le routage et la recherche par symbole. Si `scripts/run/run.gd`, `scripts/acteurs/ennemi.gd`, `scripts/acteurs/boss.gd`, `scripts/menu/menu.gd` ou `autoload/reglages_joueur.gd` continuent de recevoir plusieurs responsabilités, ils devront être découpés par comportement lors d'une refonte dédiée, avec tests avant/après.
