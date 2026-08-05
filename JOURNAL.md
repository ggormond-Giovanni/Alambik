# Journal — Alambic

Historique des décisions et des mesures. Jamais lu automatiquement ; on vient y
chercher pourquoi une chose est comme elle est.

## 2026-08-05 — Implémentation de la V1

Le plan en dix-sept tâches a été exécuté d'un trait. Ce qui a résisté, dans
l'ordre où ça s'est présenté :

**Le harnais mentait vert.** Une erreur de parse dans un script d'interface que
personne ne chargeait ne produisait ni échec de test ni `SCRIPT ERROR`.
`sondes/selftest.gd` charge désormais tous les `.gd` et tous les `.tscn` du
projet et vérifie que chaque script peut s'instancier.

**Le harnais tournait en silence.** Une erreur d'exécution interrompt
`_initialize()` sans atteindre `quit()` : le processus tournait indéfiniment
sans rien afficher. `tests/lanceur.gd` a une ceinture de sécurité dans
`_process`.

**Cinq blocages successifs trouvés par la sonde**, tous invisibles depuis le PC
en jouant à la main quelques minutes :

1. *Ennemis coincés contre un bloc.* Un rampant pousse contre l'obstacle pour
   l'éternité, la page ne se vide jamais. Contournement latéral quand la
   position ne change plus alors que la vitesse est non nulle.
2. *Ennemis apparus dans un bloc.* Intouchables : les projectiles heurtent le
   bloc avant eux. Les positions d'apparition évitent les obstacles.
3. *Tirs dans la pierre pendant deux minutes.* Le bot croyait sa ligne de tir
   libre : les requêtes de rayon lancées depuis `_process` reviennent vides, et
   la ligne mathématique passait à quatre pixels d'un bloc alors que le
   projectile a un rayon de treize. D'où `scripts/geometrie.gd`, avec une marge
   et huit tests.
4. *Le scribe essaimeur rendait la page infinie.* Il invoquait plus vite qu'on
   ne tuait, et le tir automatique vise le plus proche — donc jamais lui.
   Réserve d'encre finie : six invocations sur sa vie, et personne n'invoque
   au-delà de dix ennemis présents.
5. *Flèche double faisait rater les deux projectiles.* Un éventail de 14°
   écarte de 76 px à 620 px : les deux tirs passaient de chaque côté d'une
   sentinelle. Les projectiles multiples partent maintenant presque parallèles,
   simplement décalés de 30 px.

**Le tir vise où la cible sera**, pas où elle est, avec un vol borné à 0,8 s. Un
scribe qui recule survivait à trois cents projectiles.

**Le bot a été refait trois fois.** Un bot faible mesure la difficulté du bot,
pas celle du jeu — c'est un mauvais instrument, et il a d'abord fait croire à un
équilibrage trop dur alors qu'il se coinçait dans un coin.

### Mesures du jour

- `./verifier.sh` : 15 suites, 522 assertions, 0 échec, aucun `SCRIPT ERROR`.
- `./sondes/vingt_runs.sh` : **0 échec sur 20**. 18 runs sur 20 atteignent la
  page 10 (le boss), une victoire, deux morts avant (pages 2 et 7). Entre 8 et
  133 créatures abattues par run.
- APK debug signé : 28,6 Mo, arm64-v8a uniquement.
- Aucune mesure sur appareil : aucun téléphone n'était connecté (`adb devices`
  vide). Les images par seconde réelles, le confort du pouce et la lisibilité
  restent inconnus, et le resteront tant que le téléphone n'aura pas parlé.

### Écarts assumés

- `Reglages` est une classe de constantes et non un autoload : les suites
  headless doivent lire l'équilibrage sans monter de SceneTree.
- Le héros appartient à `Run` et non à `Salle` : ses PV traversent les pages.
- Prendre une essence au draft ne consomme pas ses composants.

### Travail parallèle

Des sprites de personnages (`assets/characters/`) ont été générés et branchés en
parallèle de cette implémentation, avec des retouches d'interface associées.
Ils ne viennent pas de la session qui a écrit ce journal. Point de vigilance :
ils sont chargés par `preload`, donc un fichier absent casse le lancement, alors
que la règle du plan est que le jeu tourne de bout en bout sans un seul sprite.
