# État de la refonte guidée par `design.txt`

`design.txt` est la source de vérité. Ce fichier décrit seulement ce qui est
déjà jouable et distingue explicitement les prototypes des décisions finales.

## Où chercher quoi

| Besoin | Source |
|---|---|
| Régler les valeurs provisoires | `data/reglages.gd` |
| Modifier les 16 Améliorations | `data/catalogue_reactifs.gd` |
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
  testée place environ 2/4/5/6 Améliorations avant 5/10/15/20.
- Pool actuel strict de 22 Améliorations : 9 Projectile, 7 Héros, 6 Phénomène.
  Toute Amélioration qui coûte des dégâts rend des impacts, et aucune n'en coûte
  plus de 30 % seule : les multiplicateurs s'additionnent d'une carte à l'autre.
- Équipement : chaque emplacement porte un profil — Anneau I offensif, Anneau II
  de soutien, Collier défensif — multiplié par ×1,30 par Monde d'origine. La
  Forge multiplie ce profil, elle ne le remplace plus.
- Alambics après 4/9/14 : soin de 20 %, trois Éléments aléatoires distincts sur
  la run, puis Fusion avec un Amélioration choisi sans perdre son effet original.
  Un Amélioration déjà fusionné est retiré des choix suivants.
- Six Éléments actifs : Feu, Eau, Air, Terre, Lumière et Ténèbres. Leur effet
  dépend de la famille de l'Amélioration. Foudre n'est pas implémentée.
- Un coffre évolutif unique par tentative, fondé sur le meilleur palier vaincu,
  avec arrivée, verrou, ouverture lumineuse et révélation de la récompense avant
  le retour automatique ; le Grand coffre conserve sa garantie d'équipement.
- Équipement : deux Anneaux et un Collier ; un objet de prototype par chapitre,
  Forge permanente par objet, retrait volontaire et aucun doublon requis.
- Mine : grande arène dézoomée, survie de 5 minutes à apparitions progressives,
  XP de run, soin à chaque niveau et boss final dans une phase séparée,
  récompensée en Pierres de forge.
- Épreuves rituelles : cinq miniboss consécutifs. Avant chacun, le jeu tire
  automatiquement une Amélioration différente et un Élément d'Alambic différent,
  puis ajoute l'Amélioration et sa Fusion sans écran de choix. Chaque victoire
  donne ou améliore toujours une capacité permanente.
- Courbe de campagne : une fonction du palier, pas une table de Mondes. Chaque
  passage de chapitre vaut ×1,132 PV et ×1,060 dégâts, soit ×1,45 et ×1,19 par
  Monde répartis sans marche d'entrée, puis ×3,6 PV et ×1,75 dégâts sur les
  vingt salles. Les six premiers paliers sont adoucis (×0,62 au premier
  chapitre, courbe pleine à la fin du Monde II) pour qu'un compte neuf atteigne
  son premier coffre. La formule reste définie au-delà du trentième palier.
- Progression permanente entièrement poussable : les trente Maîtrises ont cinq
  rangs (un ou deux pour les déblocages), la Forge monte au niveau 60 à
  +2,5 % dégâts/PV par niveau, et les capacités atteignent le rang 10. Les
  branches offensive et défensive valent chacune environ ×11 dans leur
  spécialité complète, pour le même prix.
- Économie : le premier rang des trente Maîtrises reste finançable sur une
  campagne ; les rangs suivants coûtent ×1,85 l'un de l'autre et constituent le
  farm. La Mine indexe ses Pierres sur le palier atteint.
- Direction pixel art moderne généralisée : campagne, Mine, Épreuves, menus et
  transitions utilisent des peintures et sprites 16-bit modernes, une palette
  fantasy plus lumineuse, des volumes éclairés et des VFX contemporains.
- Loadout : un Sort, un Passif et un Ultime. La Maîtrise Utilitaire peut ouvrir
  le deuxième Passif et jusqu'à quatre rerolls d'Améliorations.
- Le Sort et l'Ultime ont chacun leur icône sur le bord droit du combat. Le Sort
  accepte en plus un raccourci réglable dans les Réglages : icône seule, tape
  rapide, ou double tape rapide dans la zone de déplacement.
- Les listes paginées — Équipement, Sorts, sélection de grimoire — se
  parcourent au balayage horizontal ; les flèches restent en secours.
- L'accueil utilise `assets/visual/menu_futur.png`, une seule peinture pour
  toutes les proportions d'écran. Ses repères vivent dans la référence de
  l'image et passent par `Retro16.rect_menu`, si bien que le décor, les textes
  et les zones tactiles restent alignés à toute hauteur.
- Les zones tactiles invisibles passent toutes par `StyleInterface.zone_tactile`,
  qui neutralise les cadres de survol, de clic et de focus dessinés par Godot.
- Les interfaces partagent les mêmes entrées/sorties quintiques. Les listes de
  choix apparaissent en cascade, les rerolls se remplacent par fondu et les
  pages principales glissent latéralement. Boutons et onglets ont des réactions
  tactiles amorties. Les fonds, en-têtes, surfaces, sélecteurs, cases et curseurs
  suivent un langage commun fantasy lumineux et alchimique ; les changements de catalogue
  sont directionnels plutôt qu'instantanés. « Effets réduits » raccourcit tous
  ces mouvements.
- Le niveau de compte porte le socle de statistiques du héros — dégâts, PV et
  cadence de base. Les Maîtrises, l'équipement et les Passifs sont des
  multiplicateurs appliqués dessus. Les annexes restent séparées de la
  progression de campagne.
- Chaque Passif porte un effet permanent réellement branché, en plus de son
  effet ponctuel. Les Sorts ajoutent environ un quart de la puissance soutenue
  du héros, les Ultimes effacent une rencontre ; deux suites mesurent ces
  rapports.
- Dans les Maîtrises, toucher un nœud le consulte ; un bouton dédié l'améliore.
  Chaque nœud affiche le prix de son prochain rang.

## Prototypes assumés, pas décisions finales

- Les chiffres de combat, d'XP, de Forge, de coffres, de Maîtrises et de rangs
  de capacité sont centralisés ; leur courbe est mesurée par les suites et par
  la sonde, mais reste à ajuster avec les retours de parties.
- L'arbre compte trente Maîtrises : dix paliers Offensifs, Défensifs et
  Utilitaires, chacun poussable sur cinq rangs.
- La sonde `--maxe` dote un compte entièrement farmé. Le bot n'utilise ni Sort
  ni Ultime : ses résultats sont un plancher, pas la puissance réelle d'un
  joueur au maximum.
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

## Vérification du 14 août 2026

- `./verifier.sh` : 26 suites, 8 588 assertions, 0 échec ; tous les scripts et
  scènes chargent sans erreur.
- Sonde de vingt graines au chapitre 1 : 20 victoires, 0 blocage.
- Compte neuf (`--vierge`) au chapitre 1 : salles 5 à 13 sur cinq graines, aucune
  victoire. Le premier coffre est acquis à chaque tentative, donc la progression
  démarre. Au chapitre 10, mort salle 1 : la campagne se franchit en farmant.
- Compte entièrement farmé (`--maxe`) au chapitre 30 : cinq victoires sur cinq,
  entre 2 min 55 s et 4 min 07 s.
- Les mesures dites « sans Maîtrise » d'avant le 14 août étaient fausses : la
  sauvegarde de test portait `mode_dev=true`, qui ouvre toutes les Maîtrises au
  rang maximal. Une sonde n'écrit plus dans la sauvegarde.
- L'accueil premium validé est réellement intégré : navigation persistante,
  lancement immédiat du chapitre sélectionné et respiration légère du héros.
- Le panneau Pause premium et le choix premium des Améliorations sont
  fonctionnels et alimentés par les vraies données de la run.
- La caméra Mine et le fond utilisent désormais la même surface de monde ; la
  zone vide visible sur PC et les entités apparemment hors arène ont disparu.
- Captures réelles contrôlées dans `tmp/refonte_interface` : accueil, Pause,
  choix d'Amélioration, Mine, Équipement, Maîtrises, Sorts, Réglages, Campagne,
  HUD de combat, portail, Alambic, récompense de Sort et inventaire de Pause.
- La passe premium couvre maintenant aussi l'Alambic, les récompenses de
  miniboss, le bilan de fin de run et le joystick. Les anciens fonds génériques
  ne subsistent que dans les voiles animés, où ils servent volontairement de
  matière sombre sous les sceaux et les bandes de transition.
- Après essai, le héros et son tir sont revenus au rythme lisible d'origine :
  560 px/s pour le héros et 900 px/s pour le projectile. Le léger multiplicateur
  de vitesse des monstres reste à 1,10.
- La sonde de vingt graines termine ses vingt processus sans erreur de script
  ni blocage. Le pilote de test contourne maintenant les obstacles avant
  d'entrer dans le portail, comme le fait déjà le déplacement réel.
- Toutes les interfaces premium occupent la hauteur disponible sans bande
  noire. Les cadres du haut et du bas gardent leurs proportions ; les formats
  très hauts révèlent une bande de décor intermédiaire au lieu d'étirer les
  textes et ornements.
- L'accueil choisit une composition 9:16 ou haute selon le téléphone. Le suivi
  du chapitre affiche l'étage maximal atteint ; l'étoile de complétion
  n'apparaît que lorsque les trois chapitres du monde affiché sont terminés.
- L'arène possède une peinture dédiée aux écrans hauts. Sa zone praticable est
  plafonnée et recentrée, et les silhouettes de combat sont agrandies de 8 %
  afin de réduire l'impression de vide sans modifier leurs hitbox.

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
