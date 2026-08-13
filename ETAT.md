# État de la refonte guidée par `design.txt`

`design.txt` est la source de vérité. Ce fichier décrit seulement ce qui est
déjà jouable et distingue explicitement les prototypes des décisions finales.

## Où chercher quoi

| Besoin | Source |
|---|---|
| Régler les valeurs provisoires | `data/reglages.gd` |
| Modifier les 16 Augments | `data/catalogue_reactifs.gd` |
| Modifier les 6 Éléments et leurs Fusions | `data/catalogue_elements.gd` |
| Modifier mondes, chapitres et paliers | `data/chapitres.gd` |
| Modifier les rencontres | `data/vagues.gd` |
| Modifier coffres et récompenses d'Épreuve | `data/recompenses.gd` |
| Modifier l'équipement | `data/catalogue_objets.gd`, `ui/equipement.gd` |
| Changer l'enchaînement d'une run | `scripts/run.gd` |
| Vérifier le dépôt | `./verifier.sh`, puis `./sondes/vingt_runs.sh` |

## Boucle jouable actuelle

- Campagne de 10 mondes × 3 chapitres × 20 salles.
- Rencontres décrites salle par salle, avec seulement des variations d'ordre
  contrôlées ; la vague suivante arrive immédiatement après un clean ou après
  le délai de pression provisoire.
- Miniboss aux salles 5, 10 et 15 ; boss final à la salle 20. Les dix miniboss
  tournent sans répétition consécutive, possèdent chacun une silhouette et une
  attaque signature télégraphiée. Les
  chapitres 1 et 2 se ferment sur un miniboss ; le chapitre 3 de chaque monde
  utilise l'un des dix boss signature uniques.
- Après le nettoyage, un portail apparaît dans l'arène ; le héros doit le
  rejoindre pour quitter la salle. Un voile à sceau alchimique fond vers la
  salle suivante ; les panneaux de niveau gardent la priorité.
- XP de run et choix immédiat parmi 3 cartes, avec 6 choix maximum. La courbe
  testée place environ 2/4/5/6 Augments avant 5/10/15/20.
- Pool actuel strict de 16 Augments : 6 Projectile, 5 Héros, 5 Phénomène.
- Alambics après 4/9/14 : soin de 20 %, trois Éléments aléatoires distincts sur
  la run, puis Fusion avec un Augment choisi sans perdre son effet original.
  Un Augment déjà fusionné est retiré des choix suivants.
- Six Éléments actifs : Feu, Eau, Air, Terre, Lumière et Ténèbres. Leur effet
  dépend de la famille de l'Augment. Foudre n'est pas implémentée.
- Un coffre évolutif unique par tentative, fondé sur le meilleur palier vaincu,
  avec arrivée, verrou, ouverture lumineuse et révélation de la récompense avant
  le retour automatique ; le Grand coffre conserve sa garantie d'équipement.
- Équipement : deux Anneaux et un Collier ; un objet de prototype par chapitre,
  Forge permanente par slot, aucun doublon requis.
- Mine : grande arène dézoomée, survie de 5 minutes à apparitions progressives,
  XP de run, soin à chaque niveau et boss final dans une phase séparée,
  récompensée en Pierres de forge.
- Épreuves rituelles : cinq miniboss consécutifs ; chaque victoire donne ou
  améliore une capacité tant que l'Arsenal n'est pas complet.
- Direction 16-bit généralisée : campagne, Mine, Épreuves, menus et transitions
  utilisent la même grille de 4 pixels, la même palette resserrée et des poses
  discrètes. Les onze créatures, dix miniboss et dix boss signature possèdent
  des silhouettes procédurales distinctes.
- Loadout : un Sort, un Passif et un Ultime. La Maîtrise Utilitaire peut ouvrir
  le deuxième Passif et un reroll d'Augments.
- Les interfaces partagent les mêmes entrées/sorties quintiques. Les listes de
  choix apparaissent en cascade, les rerolls se remplacent par fondu et les
  pages principales glissent latéralement. Boutons et onglets ont des réactions
  tactiles amorties. Les fonds, en-têtes, surfaces, sélecteurs, cases et curseurs
  suivent un langage commun 16-bit sombre et alchimique ; les changements de catalogue
  sont directionnels plutôt qu'instantanés. « Effets réduits » raccourcit tous
  ces mouvements.
- Le niveau de compte donne de l'avancement, aucune statistique et aucun Sort.
  Les annexes sont séparées de la progression de campagne.

## Prototypes assumés, pas décisions finales

- Les chiffres de combat, d'XP, de Forge, de coffres, de Maîtrises et de rangs
  de capacité sont centralisés ; leur première courbe complète est jouable mais
  reste à ajuster avec les retours de parties.
- L'arbre compte trente Maîtrises : dix paliers Offensifs, Défensifs et
  Utilitaires, avec une montée volontairement forte jusqu'au dernier monde.
- Les Gouttes des coffres progressent sur les trente chapitres. Une campagne à
  grands coffres moyens finance statistiquement l'arbre sans le rendre gratuit
  dans les premiers mondes.
- Les identifiants des trente anciens objets sont conservés uniquement pour la
  migration des sauvegardes ; aucun effet spécial d'équipement n'est inventé.
- Onze créatures communes composent les rencontres : contact/crachat, salve,
  charge, invocation, orbite, bélier, harcèlement et onde radiale. Les
  Cachets phaseurs changent de côté, les Fuseaux tissent des lignes parallèles
  et les Fioles volatiles annoncent leur explosion. Les compositions restent
  ajustables après retours de parties.

## Vérification du 13 août 2026

- `./verifier.sh` : 23 suites, 8 000 assertions, 0 échec ; tous les scripts et
  scènes chargent sans erreur.
- Captures réelles du menu et d'une salle contrôlées après généralisation du
  rendu 16-bit ; aucun visuel peint n'est chargé par le projet.
- Captures téléphone contrôlées sur le menu, deux silhouettes de miniboss et
  une rencontre contenant une Fiole volatile.
- La sonde de vingt graines termine ses vingt processus sans erreur de script,
  mais 8 restent bloqués après nettoyage parce que le bot n'entre pas dans le
  portail (`ennemis restants=0`). Le problème est dans le pilotage de sonde et
  survient avant l'introduction des trois nouvelles créatures.

## Toujours à concevoir selon `design.txt`

- Mécanique environnementale et bestiaire propres à chacun des dix mondes.
- Variantes de bestiaire propres aux dix mondes et polissage final des boss.
- Effets finaux des équipements et rattrapage des anciens objets.
- Ajustement fin de l'économie et paliers supérieurs des modes annexes.
- Identité finale de l'Air, détails finaux des transformations et éventuelle
  Foudre.
- Contrôle mobile définitif et post-game.

## Vérification du 11 août 2026

- `./verifier.sh` : 23 suites, 7 888 assertions, 0 échec.
- Chargement exhaustif : aucune erreur de script ou de scène, aucun drapeau
  inerte.
- Smoke tests headless : Mine terminée après 5:00, horde nettoyée, boss abattu
  et portail traversé ; campagne passée de la salle 1 à la salle 3 par ses
  portails ; aucun `SCRIPT ERROR`.
- Sonde de 20 graines sans dotation : 20 fins de run observées, 0 blocage et
  0 erreur de script.
