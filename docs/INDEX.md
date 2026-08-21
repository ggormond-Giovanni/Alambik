# Index de travail

But : arriver au bon fichier avec le moins de contexte possible.

| Tâche | Commencer par | Puis, si nécessaire |
|---|---|---|
| Boucle d'une run, salles, récompenses | `scripts/run/run.gd` | `autoload/jeu.gd`, `data/chapitres.gd`, `data/recompenses.gd` |
| Héros, déplacement, dégâts reçus | `scripts/acteurs/heros.gd` | `scripts/combat/stats.gd`, `data/reglages.gd` |
| Ennemi commun / IA | `scripts/acteurs/ennemi.gd` | `scripts/acteurs/cerveaux.gd`, `data/catalogue_ennemis.gd` |
| Boss / gardien | `scripts/acteurs/boss.gd` | `scripts/acteurs/gardien.gd`, `data/catalogue_ennemis.gd` |
| Tirs / ciblage / impacts | `scripts/combat/` | `data/reglages.gd` |
| Améliorations / effets de run | `scripts/ameliorations/` | `data/catalogue_reactifs.gd`, `data/catalogue_elements.gd` |
| Salle, obstacles, géométrie | `scripts/monde/` | `data/vagues.gd` |
| Menu principal | `scripts/menu/menu.gd` | `ui/`, `scripts/presentation/` |
| Interface | `ui/` | `scripts/presentation/`, `human/interface/` si design demandé |
| Équilibrage | fichier précis dans `data/` | tests associés ; pas `scripts/run/run.gd` par défaut |
| Sauvegarde / progression joueur | `autoload/reglages_joueur.gd` | `data/arbre_competences.gd`, `data/catalogue_objets.gd` |
| Audio | `autoload/sons.gd` | `assets/audio/` |
| Mobile / safe area | `autoload/ecran.gd` | `docs/ops/MOBILE.md` |
| Bug de compilation | recherche du symbole/chemin | `./verifier.sh`, `sondes/selftest.gd` |
| Design global | chercher un titre dans `docs/design/GAME_DESIGN.md` | `human/` seulement si demandé |

## Règle de lecture

Les fichiers de plus d'environ 12 Ko (`run.gd`, gros acteurs, certains écrans UI, sauvegarde) ne doivent pas être chargés intégralement sans raison. Chercher d'abord le symbole, la chaîne, le signal ou la fonction concernée et lire quelques dizaines de lignes autour.

Pour l'historique d'une décision, chercher dans `docs/archive/JOURNAL.md` ; ne jamais le mettre dans le contexte de base.
