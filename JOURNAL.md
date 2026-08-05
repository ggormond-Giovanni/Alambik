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
- Prendre une essence au draft consomme ses composants, comme a l'alambic
  (corrige le 2026-08-05 au soir).

## 2026-08-05 (soir) — Retours de jeu : fusions, combos, cinquante pages

Trois reproches, trois corrections. Chacune a commencé par une mesure, parce que
« trop fort » et « plus faible que ses composants » ne se règlent pas à vue.
L'instrument est `scripts/puissance.gd`, la sonde `sondes/equilibrage.gd`.

**Une fusion doit battre ses composants.** Mesure d'avant : trois essences sur
dix étaient perdantes, Rafale d'alambic à 0,56. Elles coûtaient deux réactifs
pour rendre moins que ce qu'on abandonnait. Réécrites, puis figées par un test
qui exige au moins 15 % de mieux que le couple, et mieux que chacun pris seul.

**Et elle doit consommer ce qu'elle consomme.** L'alambic retirait bien les deux
composants, mais l'essence proposée au draft, elle, était offerte : on gardait
tout. C'était le « trop bête » du retour. Le draft consomme désormais, et la
carte l'annonce avant le clic.

**Les combinaisons cassées.** Écart mesuré entre la meilleure main de cinq
réactifs et la médiane : 2,35, avec près de 6 entre la meilleure et la pire.
Trois causes trouvées, toutes structurelles :

- les multiplicateurs se composaient en produit — ils s'additionnent maintenant,
  ce qui reste indifférent à l'ordre d'acquisition ;
- un éclat de verre frappait à 45 % du tir d'origine, ce qui faisait d'Éclat de
  verre un multiplicateur déguisé — 28 % ;
- un projectile perforant traversait quatre ennemis à pleine puissance — il perd
  35 % par traversée et 25 % par rebond.

Écart final : 1,96, plafonné par un test à 2,2.

**Cinquante pages par chapitre, trois chapitres.** Conséquences qu'il a fallu
traiter, dans l'ordre où elles sont apparues :

1. Quarante drafts pour quinze réactifs : il faut pouvoir reprendre un réactif.
   D'où les plafonds de copies (3, 2 pour ceux qui ajoutent des projectiles, 1
   pour ceux qui ne posent qu'un effet) et la page de repos quand tout est plein.
2. Écrire cinquante compositions de vagues à la main par chapitre serait
   illisible : `data/vagues.gd` décrit des paliers, la page en découle, et le
   tirage reste reproductible à graine égale.
3. La difficulté s'effondrait. Mesure : à la page 50, le héros valait 16 fois ce
   que la page lui opposait. La montée des créatures était une droite quand la
   puissance du joueur est une exponentielle. Courbe géométrique (×16 en PV sur
   un chapitre), rendement décroissant sur les copies, draft une page sur deux :
   rapport ramené entre 1,0 et 2,5 sur le premier chapitre.

Session de 5 à 7 minutes annoncée par la spec : une descente de cinquante pages
en demande nettement plus. C'est un choix assumé du projet, pas un oubli — mais
la spec dit encore le contraire.

### Travail parallèle

Des sprites de personnages (`assets/characters/`) ont été générés et branchés en
parallèle de cette implémentation, avec des retouches d'interface associées.
Ils ne viennent pas de la session qui a écrit ce journal. Point de vigilance :
ils sont chargés par `preload`, donc un fichier absent casse le lancement, alors
que la règle du plan est que le jeu tourne de bout en bout sans un seul sprite.
