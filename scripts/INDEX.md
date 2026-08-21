# Carte des scripts

| Domaine | Dossier | Responsabilité |
|---|---|---|
| Run | `run/` | orchestration d'une tentative, transitions, récompenses |
| Acteurs | `acteurs/` | héros, ennemis, boss, IA spécialisée |
| Combat | `combat/` | projectile, tir, ciblage, stats et priorités |
| Monde | `monde/` | salle, géométrie, adaptation du terrain |
| Améliorations | `ameliorations/` | effets et logique des choix de run |
| Présentation | `presentation/` | dessin procédural, palette, polices, styles |
| Entrées | `entrees/` | joystick, balayage, raccourcis tactiles |
| Menu | `menu/` | accueil et navigation principale |
| Développement | `dev/` | capture et outils qui ne portent pas le gameplay |

À la racine restent quelques petits scripts chargés directement par chemin depuis `run/run.gd` : `fond.gd`, `effets.gd`, `cadre_retro.gd`, `voile_transition.gd`. Ne pas les déplacer isolément sans mettre à jour l'orchestrateur.
