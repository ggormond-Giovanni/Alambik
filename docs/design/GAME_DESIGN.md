# REFONTE GAME DESIGN — SOURCE DE VÉRITÉ ACTUELLE

## 0. CONTEXTE CRITIQUE POUR L'IMPLÉMENTATION

Le jeu existe déjà et possède une base jouable de type Archero-like.

**CE DOCUMENT NE DÉCRIT PAS UN JEU À RECRÉER.**

Il décrit les modifications de game design à appliquer progressivement au jeu existant.

### Règle absolue

Avant toute modification :

1. inspecter l'architecture existante ;
2. identifier les systèmes déjà présents ;
3. conserver ce qui fonctionne et correspond à cette vision ;
4. adapter les systèmes existants plutôt que les réécrire ;
5. ne jamais lancer une refonte globale sans nécessité technique réelle ;
6. isoler les changements pour pouvoir les tester indépendamment.

Le gameplay de base du héros existe déjà et est globalement satisfaisant.

Les gros chantiers sont surtout :

* structure des runs ;
* Améliorations ;
* Alambic ;
* progression ;
* équilibrage ;
* patterns ennemis ;
* miniboss ;
* boss ;
* économie.

Les patterns des monstres devront être repris **un par un dans une phase ultérieure**.

---

# 1. PHILOSOPHIE GÉNÉRALE

Le jeu doit être un Archero-like :

* très fluide ;
* agréable immédiatement ;
* relativement simple à comprendre ;
* beaucoup plus profond lorsqu'on commence à theorycraft ;
* plus compact qu'Archero ;
* plus généreux ;
* légèrement orienté farm ;
* fortement orienté skill ;
* sans mécanique artificielle destinée à ralentir le joueur.

Le joueur doit avoir la sensation que :

**même quelques minutes de jeu représentent un petit progrès vers la fin.**

Le jeu doit respecter le temps du joueur.

---

# 2. SKILL VS FARM

Principe fondamental :

**le skill permet de progresser plus vite ; le farm permet de réduire progressivement la difficulté.**

Un excellent joueur doit pouvoir battre du contenu en étant fortement sous-équipé.

Un joueur moins performant doit pouvoir :

* retenter ;
* gagner XP et ressources ;
* améliorer son compte ;
* revenir progressivement plus puissant ;
* finir par franchir l'obstacle sans devoir devenir un expert mécanique.

Cependant :

**le farm ne doit jamais supprimer totalement l'esquive.**

Même avec énormément de progression permanente, le jeu reste un jeu d'esquive.

Exemple conceptuel :

* victoire difficile sur un chapitre ;
* tentative immédiate du suivant = extrêmement difficile mais possible ;
* ~20 min de farm = différence déjà perceptible ;
* ~1 h 30 de farm = chapitre sensiblement plus confortable.

Ces durées ne sont PAS des valeurs finales d'équilibrage.

Un excellent joueur peut éventuellement avancer environ 1 à 2 mondes sans réellement farmer.

En revanche, ignorer longtemps :

* le farm de campagne ;
* la Mine ;
* les Épreuves rituelles ;

doit progressivement rendre l'avancée extrêmement difficile.

---

# 3. MONÉTISATION / FOMO

Le jeu ne doit contenir **aucun avantage gameplay payant**.

Si le jeu fonctionne commercialement, la seule monétisation envisagée est :

**cosmétiques / skins.**

À NE PAS introduire :

* énergie ;
* tickets limitant les runs ;
* quotidiennes obligatoires ;
* streak de connexion ;
* bonus nécessitant une connexion quotidienne ;
* système où l'absence fait perdre des ressources ;
* publicité donnant des avantages ;
* revive payant ;
* équipement exclusif payant ;
* doublons obligatoires.

Le joueur doit pouvoir quitter le jeu plusieurs semaines puis revenir sans avoir l'impression d'avoir raté quelque chose.

Un éventuel système de récompense AFK n'est PAS décidé.

S'il existe un jour, il devra récompenser le retour sans créer d'obligation de connexion.

---

# 4. CAMPAGNE

## Structure

La campagne cible :

**10 mondes × 3 chapitres = 30 chapitres.**

Chaque monde représente une vraie identité visuelle et mécanique.

Les 3 chapitres d'un même monde mutualisent volontairement beaucoup de contenu afin de garder un scope de développement raisonnable.

---

# 5. IDENTITÉ DES MONDES

Chaque monde possède :

* une direction artistique propre ;
* une mécanique environnementale signature ;
* un pool principal de monstres ;
* des miniboss ;
* un boss signature.

La mécanique environnementale apparaît **régulièrement mais pas systématiquement**.

Exemple :

Monde volcanique → coulées de lave dans certaines rencontres.

La mécanique d'un monde :

* peut modifier certaines salles ;
* peut modifier certaines vagues ;
* peut produire des variantes de miniboss ;
* disparaît au monde suivant.

Le but est de renouveler le gameplay sans empiler définitivement dix couches de mécaniques.

---

# 6. PROGRESSION DES MONSTRES DANS UN MONDE

Cible actuelle :

### Chapitre 1

Environ **4 types de monstres**.

### Chapitre 2

Environ **5 types**.

### Chapitre 3

Environ **6 types**.

Un nouveau type de monstre est donc introduit à chaque chapitre du monde.

La difficulté augmente aussi via :

* augmentation des statistiques ;
* augmentation du nombre d'ennemis ;
* vagues plus denses ;
* compositions plus complexes.

La difficulté ne doit PAS uniquement être produite par des ennemis devenant des sacs à PV.

Les nouveaux monstres devront créer de nouvelles interactions avec les anciens.

---

# 7. RENCONTRES

Les rencontres ne doivent pas être entièrement procédurales.

Principe retenu :

**rencontres principalement conçues à la main + quelques variantes contrôlées.**

Une salle doit posséder une identité relativement stable.

Certaines variantes peuvent modifier :

* positions de spawn ;
* ordre d'une vague ;
* quelques ennemis ;
* composition secondaire.

Le joueur peut donc apprendre les chapitres tout en évitant une répétition parfaitement identique.

Le hasard principal d'une run doit venir du build, pas de rencontres complètement imprévisibles.

---

# 8. STRUCTURE D'UN CHAPITRE

Un chapitre contient :

**20 salles.**

Objectifs de durée lorsque le joueur possède une puissance appropriée :

### Chapitres 1 et 2

Environ **10 minutes**.

### Chapitre 3

Environ **15 minutes**.

Ces valeurs sont des cibles de rythme, pas des limites artificielles.

Un joueur très puissant doit pouvoir finir un ancien chapitre beaucoup plus rapidement.

Le jeu ne doit jamais ralentir artificiellement un joueur qui clean extrêmement vite.

---

# 9. SYSTÈME DE VAGUES

Les salles utilisent principalement des combats à plusieurs vagues.

Le système est hybride :

### Cas A — joueur très puissant

La vague est entièrement détruite.

→ la suivante commence immédiatement.

### Cas B — joueur lent

La vague n'est pas terminée après un certain timer.

→ la vague suivante peut apparaître malgré les ennemis encore vivants.

Conséquences :

* un joueur puissant n'attend jamais inutilement ;
* un manque de DPS augmente naturellement la pression ;
* il n'est pas nécessaire de simplement gonfler les PV pour augmenter la difficulté.

Attention lors de l'équilibrage :

éviter un effet boule de neige trop brutal où une légère faiblesse de DPS provoque immédiatement une accumulation impossible à rattraper.

---

# 10. TRANSITIONS ENTRE SALLES

Une fois une salle terminée :

le joueur peut passer à la suivante **immédiatement**.

Pas de :

* longue marche jusqu'à une porte ;
* transition lente ;
* écran de chargement perceptible ;
* animation inutile.

Le jeu doit donner une sensation de continuité et de rapidité.

---

# 11. PALIERS 5 / 10 / 15 / 20

Les salles :

**5 / 10 / 15 / 20**

sont des paliers majeurs.

## Salles 5 / 10 / 15

Le joueur entre d'abord dans une **pré-salle**.

Cette pré-salle contient l'Alambic.

Puis :

→ combat contre un miniboss.

## Salle 20

Pas d'Alambic.

### Chapitres 1 et 2

Miniboss final / rencontre finale renforcée.

### Chapitre 3

**Boss signature du monde.**

Il existe donc :

**10 boss signature principaux au total.**

Les miniboss peuvent être réutilisés mais recevoir de petites modifications correspondant au monde actuel.

---

# 12. NIVEAU DE RUN

ATTENTION :

le **niveau de run** est distinct du niveau permanent du compte.

Chaque chapitre recommence au niveau de run initial.

Le niveau de run possède seulement :

**6 niveaux / 6 montées de niveau utiles.**

Chaque montée de niveau donne :

**un choix entre 3 Améliorations aléatoires.**

L'XP nécessaire doit être calibrée pour obtenir approximativement :

* 2 Améliorations avant la salle 5 ;
* 4 Améliorations avant la salle 10 ;
* 5 Améliorations avant la salle 15 ;
* 6 Améliorations avant la salle 20.

Donc une run complète contient au maximum :

**6 Améliorations standards.**

Les niveaux de run sont entièrement reset au chapitre suivant.

---

# 13. LEVEL-UP

Lorsqu'un niveau de run est gagné :

**le combat se met en pause immédiatement** et le choix d'Amélioration apparaît.

Principe similaire à Archero.

Le joueur choisit 1 Amélioration parmi 3.

Des rerolls pourront être obtenus via les Maîtrises permanentes.

Les Améliorations ne doivent PAS être uniquement :

* +10 % ATK ;
* +5 % critique ;
* +15 % PV.

Les Améliorations servent principalement à modifier le comportement du build.

Les petits bonus statistiques appartiennent davantage :

* aux Maîtrises ;
* à l'équipement ;
* aux systèmes permanents.

---

# 14. ALAMBIC — MÉCANIQUE CENTRALE

L'Alambic est la mécanique signature du jeu.

Il apparaît exactement :

**avant les salles 5, 10 et 15.**

Donc :

**3 utilisations maximum par chapitre.**

---

# 15. SOIN DE L'ALAMBIC

Lorsqu'un Alambic est utilisé :

**le héros récupère 20 % de ses PV maximum.**

C'est la principale source de soin garantie/native de la structure d'une run.

Cela ne signifie PAS qu'aucun Amélioration, équipement ou Passif ne peut produire du soin.

Exemple :

Régénération reste un Amélioration possible.

---

# 16. FONCTIONNEMENT DE L'ALAMBIC

Lors de chaque utilisation :

1. le joueur récupère 20 % de ses PV max ;
2. l'Alambic génère **un Élément aléatoire** ;
3. le joueur choisit l'un de ses Améliorations ;
4. cet Amélioration fusionne avec l'Élément ;
5. l'Amélioration conserve son effet original ;
6. il gagne en plus une transformation correspondant à l'Élément.

IMPORTANT :

**les Éléments ne sont PAS des Améliorations standards.**

Ils n'apparaissent jamais lors des level-ups.

Ils existent exclusivement via l'Alambic.

---

# 17. PHILOSOPHIE DES ÉLÉMENTS

L'Élément n'a PAS un comportement universel.

Son effet dépend de la famille d'Amélioration avec laquelle il est fusionné.

C'est un point critique.

Exemple :

**Feu × Projectile**

peut provoquer une brûlure.

Mais :

**Feu × Héros**

ne signifie PAS que les attaques du héros brûlent.

Il provoque une transformation du héros de type Phénix.

Ne jamais appliquer automatiquement la propriété offensive d'un Élément lorsqu'il est fusionné avec un Amélioration défensif/Héros.

---

# 18. FAMILLES D'AMÉLIORATIONS

Trois familles principales actuellement retenues :

1. **Projectile**
2. **Héros**
3. **Phénomène**

Les Éléments constituent un système séparé réservé à l'Alambic.

---

# 19. ÉLÉMENT × PROJECTILE

Règle générale :

**le projectile devient vecteur de l'Élément.**

L'Élément ajoute donc sa propriété offensive aux attaques correspondantes.

Les valeurs exactes restent à équilibrer.

---

# 20. ÉLÉMENT × PHÉNOMÈNE

Règle générale :

**le Phénomène devient vecteur de l'Élément.**

Cependant, l'intensité du proc doit dépendre de la fréquence naturelle du Phénomène.

Exemple :

un Familier qui attaque très rapidement peut appliquer fréquemment un petit effet.

Un Météore qui tombe rarement peut provoquer un effet élémentaire beaucoup plus violent.

Objectif :

éviter qu'une mécanique rapide soit automatiquement meilleure qu'une mécanique lente.

---

# 21. ÉLÉMENT × HÉROS

Règle générale :

**l'Élément transforme directement le héros.**

La transformation dépend principalement de l'Élément.

Le système ne doit PAS nécessiter une transformation différente pour chacune des combinaisons :

Égide × Feu
Régénération × Feu
Avidité × Feu
etc.

Si un Amélioration Héros est fusionné avec Feu :

* l'Amélioration Héros original continue de fonctionner ;
* le héros reçoit la transformation Feu.

Cela permet de garder un système compréhensible et raisonnable à produire.

---

# 22. ÉLÉMENTS — LISTE ACTUELLE

Pool actuellement envisagé :

* Feu ;
* Eau ;
* Air ;
* Terre ;
* Lumière ;
* Ténèbres.

**Foudre doit probablement être ajoutée.**

D'autres éléments pourront être ajoutés plus tard.

Le pool final n'est PAS encore verrouillé.

---

# 23. PROPRIÉTÉS OFFENSIVES ACTUELLEMENT ENVISAGÉES

Ces propriétés concernent surtout les fusions :

* Élément × Projectile ;
* Élément × Phénomène.

Elles ne doivent PAS être automatiquement réutilisées pour Élément × Héros.

## Feu

Orientation :

**DoT cumulatif.**

Direction actuelle :

* chaque proc applique une brûlure ;
* durée cible actuellement envisagée : ~4 secondes ;
* plusieurs brûlures peuvent être présentes simultanément ;
* dégâts relatifs à l'ATK.

Valeurs exactes : À ÉQUILIBRER.

## Eau

Orientation :

**contrôle + vulnérabilité.**

Un ennemi Mouillé :

* est ralenti ;
* reçoit davantage de dégâts.

Valeurs : À ÉQUILIBRER.

## Air

Direction actuelle :

* projectiles plus rapides ;
* effet de burst différé.

Une précédente version utilisait un déclenchement de foudre environ 1 seconde après l'attaque, non stackable.

ATTENTION :

comme Foudre doit probablement devenir un Élément indépendant, l'identité finale de l'Air doit être retravaillée.

**À CONCEVOIR.**

## Terre

Direction actuelle :

* projectile plus lent ;
* impact plus puissant.

Mécanique spéciale proposée :

le premier proc Terre sur un ennemi applique un état annulant sa prochaine attaque.

Une seule activation par ennemi.

**À TESTER**, particulièrement sur boss/miniboss.

## Lumière

Direction actuelle :

**sustain / vol de vie.**

Les procs donnent une possibilité de récupérer de la vie.

À équilibrer.

## Ténèbres

Direction actuelle :

**très gros dégâts ponctuels / variance élevée.**

Doit être plus intéressant qu'un simple « critique avec un autre nom ».

À approfondir.

## Foudre

À CONCEVOIR.

---

# 24. TRANSFORMATIONS ÉLÉMENT × HÉROS

Les valeurs suivantes sont des directions de design et non encore des valeurs finales.

## Feu — Phénix

Transformation orientée résurrection répétée.

Piste actuelle :

* environ 3 résurrections par run ;
* retour avec une quantité moyenne de PV.

Exemple cible :

plusieurs secondes chances, mais chacune moins forte qu'une résurrection Eau.

## Eau

Résurrection très qualitative.

Piste :

* 1 résurrection ;
* retour à 100 % PV.

## Air

Piste :

* résurrection à PV moyens ;
* bonus supplémentaire à définir.

À CONCEVOIR.

## Terre

Piste :

* résurrection ;
* forte augmentation de tankyness.

## Lumière

Piste :

* résurrection à PV moyens ;
* apparition d'une auréole ;
* gros buff de statistiques après le retour.

## Ténèbres

Direction différente :

**pas nécessairement de résurrection.**

À la place :

très forte augmentation offensive.

Le joueur échange donc la sécurité contre la puissance.

---

# 25. AMÉLIORATIONS PROJECTILE — POOL ACTUEL

Le pool n'est PAS définitif.

Quelques Améliorations supplémentaires seront probablement ajoutés plus tard.

## Tir multiple

Ajoute un projectile tiré simultanément.

Le gain ne doit PAS doubler gratuitement le DPS.

Chaque projectile doit donc perdre une partie de ses dégâts.

Direction actuelle :

**réduire uniquement les dégâts par projectile**, sans réduire automatiquement la vitesse d'attaque.

Valeur exacte : À ÉQUILIBRER.

## Salve

Ajoute une nouvelle séquence de tir après la première.

Même philosophie :

les dégâts individuels sont réduits afin que le DPS augmente fortement mais ne soit pas multiplié gratuitement par 2.

Valeur : À ÉQUILIBRER.

## Ricochet

Les projectiles peuvent rebondir d'un ennemi vers un autre.

## Perforation

Les projectiles traversent les ennemis.

## Fragmentation

Lorsqu'un projectile touche, il produit plusieurs projectiles secondaires.

## Homing

Les projectiles peuvent suivre/rechercher leurs cibles.

---

# 26. SYNERGIES NATURELLES ENTRE AMÉLIORATIONS

Point très important :

les Améliorations peuvent produire des interactions extrêmement puissantes **sans passer par l'Alambic**.

Exemple :

Perforation + Homing.

Le projectile traverse une cible puis peut continuer à corriger sa trajectoire.

Autre exemple :

Ricochet + Fragmentation.

Les interactions entre projectiles secondaires et trajectoires peuvent produire énormément de dégâts.

Une combinaison du type :

Homing + Perforation + Fragmentation

peut devenir pratiquement autowin contre certaines grosses vagues tout en étant moins dominante contre un boss.

**C'est volontaire.**

Le jeu autorise les builds broken.

Objectif :

le joueur doit parfois avoir le sentiment d'avoir trouvé une combinaison complètement absurde.

L'équilibrage doit empêcher qu'UNE combinaison soit systématiquement la meilleure dans toutes les situations.

Il ne doit PAS empêcher l'existence de power spikes spectaculaires.

---

# 27. AMÉLIORATIONS HÉROS — POOL ACTUEL

## Égide

Annule la première attaque subie de chaque salle.

## Régénération

Soigne le héros entre les salles.

Quantité : À ÉQUILIBRER.

## Avidité

Augmente l'XP et les Gouttes obtenues.

La nature exacte de l'XP concernée doit être vérifiée lors de l'intégration avec les systèmes existants :

**À DÉFINIR précisément entre XP de run / XP permanente / combinaison des deux.**

## Courageux

Augmente les dégâts progressivement lorsque les PV du héros diminuent.

## Mannequin

Augmente les statistiques lorsque le héros reste immobile.

Cet Amélioration doit exploiter le gameplay fondamental :

**immobile = attaque automatique.**

Il récompense les longues fenêtres pendant lesquelles le joueur réussit à DPS sans devoir se déplacer.

---

# 28. AMÉLIORATIONS PHÉNOMÈNE — POOL ACTUEL

## Familier tireur

Invoque un familier à distance.

Il attaque automatiquement les ennemis avec des projectiles.

Exemple de Fusion :

Familier tireur + Élément → les attaques du familier appliquent cet Élément.

## Météores

À intervalles réguliers :

un météore tombe sur un ennemi.

Caractéristiques :

* impact puissant ;
* AoE ;
* fréquence relativement faible.

Les Fusions élémentaires doivent donc pouvoir être plus violentes que sur une source de dégâts rapide.

## Zone autour du héros

Crée une zone de dégâts centrée sur le héros.

Elle encourage à jouer plus proche des ennemis et augmente le risque.

## Familier gardien

Familier orienté corps-à-corps.

Il :

* attaque les ennemis ;
* peut les tanker ;
* possède des PV ;
* peut mourir ;
* revient après un certain délai.

## Orbes chargées

Le héros accumule automatiquement des orbes.

Direction actuelle :

* environ 1 orbe toutes les 2 secondes ;
* maximum d'environ 3 orbes ;
* lorsqu'une attaque est déclenchée, les orbes stockées partent avec elle.

Cela crée naturellement :

**esquive/mouvement → accumulation → arrêt → burst.**

Valeurs exactes : À TESTER.

---

# 29. NOMBRE D'AMÉLIORATIONS

Pool actuel :

### Projectile

6

### Héros

5

### Phénomène

5

Total actuel :

**16 Améliorations standards.**

Ce n'est PAS le pool final.

Quelques Améliorations supplémentaires doivent probablement être ajoutés avant la version finale.

Ne pas en ajouter automatiquement lors de l'implémentation sans nouvelle décision de design.

---

# 30. COFFRE DE RUN

Il existe **un seul coffre par tentative.**

Il évolue selon le dernier palier vaincu.

### Salle 5 vaincue

Mini coffre.

### Salle 10 vaincue

Petit coffre.

### Salle 15 vaincue

Coffre moyen.

### Salle 20 vaincue

Grand coffre.

Exemple :

le joueur atteint la salle 15 mais perd contre le miniboss.

→ coffre conservé = Petit coffre.

Il faut **vaincre** le palier pour améliorer le coffre.

Les quatre coffres ne sont PAS cumulés.

---

# 31. DÉFAITE

Il n'existe aucun checkpoint de reprise.

Mort :

→ fin de la run.

La prochaine tentative recommence depuis le début du chapitre.

Cependant :

les ressources permanentes déjà obtenues ne sont pas perdues.

Le coffre correspondant au meilleur palier vaincu est également conservé.

---

# 32. UX DE FIN DE RUN

La mort doit provoquer très peu de friction.

Séquence cible :

**mort → animation très courte → ouverture du coffre → loot → retour automatique au menu principal.**

Pas d'écran supplémentaire :

* Rejouer ;
* Menu ;
* résumé imposé ;
* statistiques bloquant le joueur.

Une éventuelle page de statistiques facultative pourra être ajoutée plus tard.

Le chemin principal doit rester extrêmement rapide.

---

# 33. RÉSURRECTION

Aucune résurrection native/gratuite universelle.

Pas de :

* pub ;
* monnaie ;
* bouton de seconde chance générique.

Une résurrection peut exister uniquement parce que le joueur l'a obtenue via :

* une Fusion ;
* un équipement ;
* un Passif ;
* une autre mécanique de build.

Elle devient donc un choix de construction et non une commodité extérieure au gameplay.

---

# 34. DROP D'ÉQUIPEMENT

Chaque monde possède son propre ensemble d'équipements.

Structure actuelle :

### Chapitre 1

Drop d'un équipement destiné à un slot Anneau.

### Chapitre 2

Drop d'un autre équipement destiné à un slot Anneau.

### Chapitre 3

Drop d'un Collier.

Les détails exacts de la compatibilité entre les deux slots Anneau restent à confirmer.

---

# 35. PROBABILITÉ DE DROP

Direction actuelle du Grand coffre :

environ **25 % de chance** de drop de l'équipement du chapitre.

Une garantie anti-malchance doit exister.

Direction actuelle :

**équipement garanti après environ 5 victoires complètes sans drop.**

Valeurs finales :

À ÉQUILIBRER.

Les coffres inférieurs peuvent avoir une très faible chance de drop, mais le Grand coffre reste la source principale.

---

# 36. ÉQUIPEMENT

Seulement :

**2 slots Anneau + 1 slot Collier.**

Le jeu ne doit PAS multiplier les emplacements d'équipement inutilement.

Chaque équipement doit proposer :

* un effet significatif ;
* un gameplay différent ;
* une vraie raison de modifier son build.

Éviter les équipements dont la seule identité est :

« celui-ci donne 7 % de stats de plus ».

---

# 37. ANCIENS ÉQUIPEMENTS

Objectif fondamental :

**un équipement intéressant obtenu au Monde 1 doit pouvoir rester jouable plus tard.**

Les nouveaux mondes ne doivent pas simplement rendre tous les anciens effets obsolètes.

Direction actuellement envisagée :

lorsque la progression atteint de nouveaux paliers d'équipement, les anciens objets peuvent recevoir un rattrapage de leurs statistiques de base.

Exemple conceptuel :

Monde 1 :
objet = 50 ATK / 50 PV.

Monde 2 :
nouvel objet = 100 ATK / 100 PV.

Débloquer le palier Monde 2 permettrait également aux objets Monde 1 d'atteindre le nouveau niveau de statistiques de base.

Ainsi :

**la progression détermine les stats brutes ; le choix d'objet détermine l'effet spécial.**

La cible de fin de jeu est une puissance permanente globale voisine de dix fois
celle du héros de départ. Stuff, Maîtrises et Passifs représentent chacun
environ un tiers de ce budget. Cette répartition mesure une puissance équivalente
incluant attaque, défense et utilitaire ; elle ne signifie pas que chaque source
multiplie toutes les statistiques par 3,33. Les bonus bruts des trois sources ne
doivent pas se composer en un multiplicateur proche de ×37.

Le déclencheur exact du rattrapage reste :

**À CONCEVOIR.**

Ne pas implémenter arbitrairement une solution définitive.

---

# 38. FORGE

Les équipements eux-mêmes ne possèdent PAS un système nécessitant des doublons.

Les Pierres de forge améliorent :

**le SLOT.**

Exemple :

Anneau gauche → Forge niveau 8.

N'importe quel anneau placé dans ce slot bénéficie du niveau de Forge correspondant.

Conséquences recherchées :

* aucun investissement perdu en changeant d'équipement ;
* aucun besoin de redropper 15 fois son objet préféré ;
* expérimentation encouragée ;
* progression permanente garantie.

---

# 39. DOUBLONS

**AUCUN DOUBLON OBLIGATOIRE.**

Ne jamais introduire une mécanique nécessitant plusieurs copies identiques pour rendre un objet compétitif.

Si des doublons existent un jour, leur rôle devra être secondaire et non obligatoire.

---

# 40. CAMPAGNE — RÔLE

La Campagne est :

* l'histoire principale ;
* la progression principale ;
* la source d'équipement ;
* une source d'XP ;
* une source de Gouttes ;
* le contenu servant à avancer vers la première vraie fin.

---

# 41. MINE

La Mine est un mode annexe court.

Objectif principal :

**farmer les Pierres de forge.**

Concept retenu :

une arène avec une **énorme vague de type Vampire Survivors**.

Les ennemis arrivent massivement depuis plusieurs directions.

Le mode doit favoriser :

* AoE ;
* gestion de foule ;
* déplacement ;
* survie sous saturation.

Il doit être court et très dynamique.

Structure exacte / durée :

À CONCEVOIR.

---

# 42. ÉPREUVES RITUELLES

Mode court destiné à obtenir/améliorer :

* Sorts ;
* Passifs ;
* Ultimes.

Concept retenu :

**5 miniboss aléatoires consécutifs.**

Très peu de temps mort.

Le mode doit davantage tester :

* esquive ;
* connaissance des patterns ;
* survie face à des menaces individuelles.

---

# 43. SORTS / PASSIFS / ULTIMES

Loadout actuel prévu :

**1 Sort + 1 Passif + 1 Ultime.**

Une Maîtrise Utilitaire avancée doit pouvoir débloquer :

**un deuxième slot Passif.**

---

# 44. SORT

Capacité faisant partie régulièrement du combat.

Le fonctionnement exact dépend du Sort.

Il peut être :

* déclenché manuellement ;
* éventuellement semi-automatique/conditionnel selon le design.

L'interface mobile doit rester simple.

Éviter une multitude de boutons.

---

# 45. PASSIF

Capacité constamment active.

Les Passifs doivent pouvoir modifier :

* comportement ;
* statistiques ;
* synergies ;
* survie ;
* économie ;
* interactions avec d'autres systèmes.

---

# 46. ULTIME

L'Ultime doit rester une catégorie à part car il possède une vraie fonction.

Il utilise :

**une jauge.**

Pas simplement un cooldown.

La jauge se recharge pendant le combat.

Objectif actuel :

environ **3 à 4 utilisations sur une run complète.**

Les Ultimes doivent être particulièrement satisfaisants contre les vagues.

Exemple de philosophie :

un Ultime peut quasiment nettoyer un écran de monstres.

En revanche :

**il ne doit pas supprimer gratuitement un boss.**

Sa puissance contre une cible unique doit être sensiblement plus faible ou moins adaptée.

---

# 47. NIVEAU DE COMPTE

Le niveau permanent du compte est différent du niveau de run.

Son rôle principal n'est PAS de simplement donner :

+X % ATK par niveau.

Fonction actuellement prévue :

**débloquer progressivement du contenu annexe plus avancé.**

Exemples :

* Mine supérieure ;
* Épreuves rituelles supérieures ;
* meilleurs paliers de farm.

Le niveau de compte représente principalement l'avancement global.

---

# 48. MAÎTRISES

Les Gouttes servent à progresser dans un arbre de Maîtrises permanent.

Trois branches prévues :

### Offensive

Petits bonus offensifs.

### Défensive

Petits bonus défensifs.

### Utilitaire

Confort, mobilité, économie et fonctionnalités.

La majorité des nœuds :

**petits bonus permanents.**

Certains nœuds majeurs :

**très gros déblocages.**

Exemples validés comme direction :

* +1 reroll d'Amélioration ;
* potentiellement deuxième reroll plus tard ;
* deuxième slot Passif.

L'arbre complet n'est PAS encore conçu.

---

# 49. REROLLS

Les level-ups proposent 3 Améliorations aléatoires.

Les Maîtrises permettent progressivement d'obtenir :

* au moins 1 reroll ;
* potentiellement 2 à terme.

Le but est :

**RNG présente mais contrôlable.**

Une mauvaise RNG doit produire un build différent, pas nécessairement une run morte.

---

# 50. PHILOSOPHIE DE RNG

Le joueur ne doit pas pouvoir garantir exactement le même build à chaque run.

Cependant :

la RNG ne doit pas produire régulièrement des choix complètement inutiles.

Objectif :

**RNG d'opportunité, pas RNG punitive.**

Le theorycraft consiste en partie à construire quelque chose de puissant avec ce que la run propose.

---

# 51. FIN DU JEU

Première vraie fin :

**terminer la campagne des 10 mondes.**

Le joueur doit pouvoir se dire :

« J'ai terminé le jeu. »

Le jeu n'a PAS vocation à retenir artificiellement le joueur pour toujours.

---

# 52. POST-GAME

Non prioritaire actuellement.

Ne pas consacrer du temps important à cette partie tant que la campagne n'est pas bonne.

## Panthéon

Contenu de maîtrise autour des boss des 10 mondes.

Possiblement boss rush.

Format exact :

À CONCEVOIR.

## Chaos / Monde infini

Mode permettant de continuer quasiment indéfiniment.

Concept :

mélanger aléatoirement des éléments déjà produits :

* monstres de différents mondes ;
* mécaniques environnementales ;
* miniboss ;
* compositions ;
* scaling très élevé.

Le mode peut devenir volontairement extrêmement difficile.

À très haut niveau :

**l'équilibrage parfait n'est plus une obligation.**

Le joueur continue essentiellement pour :

* optimiser ;
* tester des builds broken ;
* pousser toujours plus loin.

---

# 53. CONTRÔLES

Le système fondamental reste :

**le personnage se déplace → il n'attaque pas.**

**le personnage est immobile → attaque automatique.**

Cela ne doit pas être supprimé.

Deux méthodes de déplacement doivent éventuellement être comparées :

### Option A

Joystick flottant type Archero.

### Option B

Tap-to-walk / déplacement tactile plus direct.

Aucune décision définitive.

**NE PAS modifier le système de contrôles actuel pendant une refonte d'équilibrage sans demande explicite.**

Le changement éventuel doit être prototypé séparément.

---

# 54. PRINCIPES DE DESIGN NON NÉGOCIABLES

1. Le jeu reste un jeu d'esquive.

2. Le skill permet d'avancer plus rapidement.

3. Le farm permet de compenser une partie du manque de skill.

4. Le farm ne doit pas rendre totalement inutile l'esquive.

5. Une tentative ratée doit quand même produire de la progression.

6. Aucun système quotidien obligatoire.

7. Aucun système d'énergie.

8. Aucun FOMO.

9. Aucun doublon d'équipement obligatoire.

10. Changer d'équipement ne doit pas détruire les investissements permanents.

11. Les Améliorations doivent principalement modifier le gameplay.

12. Les builds extrêmement puissants sont autorisés.

13. Toutes les combinaisons n'ont pas besoin d'avoir exactement le même DPS.

14. Aucune combinaison unique ne doit dominer systématiquement toutes les autres situations.

15. L'Alambic doit provoquer une vraie montée en puissance.

16. Les Fusions élémentaires doivent être immédiatement perceptibles.

17. Un Élément n'a pas la même fonction selon qu'il est fusionné avec Projectile, Phénomène ou Héros.

18. Les 6 Améliorations d'une run doivent produire des décisions importantes plutôt qu'une accumulation de petits bonus.

19. Après le dernier Alambic, le joueur doit avoir suffisamment de temps pour profiter de son build final.

20. Un joueur puissant doit terminer les anciens chapitres beaucoup plus rapidement.

21. Ne jamais ajouter artificiellement de l'attente pour normaliser la durée d'un chapitre.

22. Les transitions doivent être extrêmement rapides.

23. La mort doit permettre un retour rapide au gameplay.

24. Le jeu doit posséder une vraie fin.

25. Le post-game est facultatif.

---

# 55. DÉCISIONS ACTUELLEMENT VERROUILLÉES

À considérer comme la direction actuelle de référence :

* jeu existant à modifier, pas à recréer ;
* 10 mondes ;
* 3 chapitres par monde ;
* 30 chapitres ;
* 20 salles par chapitre ;
* rencontres principalement fixes avec quelques variantes ;
* combats à vagues ;
* vague suivante immédiate si clean rapide ;
* miniboss aux paliers 5/10/15 ;
* salle 20 = final du chapitre ;
* boss signature uniquement au chapitre 3 ;
* 10 boss signature ;
* mécanique environnementale par monde ;
* environ 4/5/6 types de monstres sur les chapitres 1/2/3 ;
* 6 Améliorations maximum par run ;
* choix entre 3 Améliorations ;
* progression approximative 2/4/5/6 Améliorations avant 5/10/15/20 ;
* 3 Alambics ;
* Alambics avant 5/10/15 ;
* Alambic soigne 20 % PV max ;
* Alambic fournit un Élément aléatoire ;
* Élément fusionné à un Amélioration choisi ;
* Élément exclu des level-ups ;
* familles Projectile / Héros / Phénomène ;
* Élément × Projectile = propriété offensive sur projectile ;
* Élément × Phénomène = propriété adaptée au phénomène ;
* Élément × Héros = transformation du héros ;
* coffre unique évolutif ;
* coffre amélioré uniquement si le palier est vaincu ;
* aucun checkpoint ;
* mort → coffre → menu rapidement ;
* 2 anneaux + 1 collier ;
* aucun doublon obligatoire ;
* Forge appliquée aux slots ;
* Campagne = équipements/progression principale ;
* Mine = énorme vague / Pierres de forge ;
* Épreuves rituelles = 5 miniboss / capacités ;

Chaque combat d'Épreuve commence avec une Amélioration aléatoire nouvelle et
un Élément d'Alambic aléatoire, ajoutés automatiquement sous forme originale et
fusionnée. Aucun choix d'Amélioration ou d'Élément n'interrompt l'Épreuve ; la
récompense de capacité permanente reste accordée après le miniboss.
* 1 Sort ;
* 1 Passif ;
* 1 Ultime ;
* deuxième Passif via Maîtrise ;
* Ultime à jauge ;
* environ 3–4 Ultimes par run ;
* Maîtrises Offensive / Défensive / Utilitaire ;
* niveau de compte principalement utilisé pour débloquer les niveaux supérieurs des contenus annexes ;
* aucune énergie/daily/FOMO ;
* cosmétique payant uniquement si monétisation future.

---

# 56. POINTS À NE PAS INVENTER

Les systèmes suivants ne sont PAS encore suffisamment décidés.

Codex ne doit pas prendre de décisions de game design définitives à leur sujet sans nouvelle instruction :

* chiffres de dégâts ;
* PV ;
* vitesse ;
* timers ;
* scaling précis ;
* nombre final d'Améliorations ;
* nouveaux Améliorations ;
* nombre final d'Éléments ;
* mécanique finale de Foudre ;
* identité finale de l'Air ;
* valeurs exactes des effets élémentaires ;
* détails des transformations Héros ;
* arbre complet de Maîtrises ;
* économie exacte ;
* coûts de Forge ;
* vitesse de progression ;
* pool final d'équipement ;
* effets des équipements ;
* fonctionnement exact du rattrapage des anciens équipements ;
* patterns ennemis ;
* compositions finales des salles ;
* miniboss ;
* boss ;
* mécaniques des 10 mondes ;
* contrôle Joystick vs Tap-to-walk ;
* Panthéon ;
* Chaos.

Lorsqu'une valeur est nécessaire techniquement pour tester :

utiliser une constante/configuration facilement modifiable et signaler explicitement qu'elle est provisoire.

---

# 57. MÉTHODE DE MODIFICATION DU PROJET

Ne PAS appliquer tout ce document en un énorme patch.

Procéder par lots indépendants.

Ordre conseillé :

## Étape 1 — Audit

Inspecter le projet existant.

Produire :

* architecture actuelle ;
* systèmes déjà présents ;
* structure actuelle des chapitres ;
* level-up actuel ;
* Améliorations existants ;
* ennemis existants ;
* progression actuelle ;
* économie actuelle ;
* équipement actuel ;
* différence entre l'état actuel et cette spécification.

**Ne modifier aucun fichier pendant cet audit.**

## Étape 2 — Structure de run

Adapter progressivement :

* 20 salles ;
* vagues ;
* paliers ;
* 6 niveaux ;
* courbe XP ;
* 3 Alambics ;
* coffre évolutif.

Tester avant de continuer.

## Étape 3 — Améliorations

Mapper les Améliorations existants.

Conserver/réutiliser ce qui peut correspondre.

Ajouter ou modifier uniquement ce qui manque.

## Étape 4 — Alambic / Éléments

Implémenter le système élémentaire comme système séparé.

Éviter une architecture hardcodée impossible à étendre.

Chaque Amélioration doit exposer suffisamment d'informations pour pouvoir recevoir une transformation élémentaire.

## Étape 5 — Progression permanente

Adapter :

* niveau de compte ;
* Gouttes ;
* Maîtrises ;
* Forge par slot ;
* équipement ;
* drops ;
* pity.

## Étape 6 — Modes annexes

Mine puis Épreuves rituelles.

## Étape 7 — Bestiaire

Reprendre les monstres **un par un**.

Pour chaque ennemi :

* rôle ;
* pattern ;
* télégraphe ;
* vitesse ;
* menace ;
* faiblesse ;
* interaction avec les autres ennemis.

## Étape 8 — Boss

Créer/adapter les 10 boss signature lorsque le combat normal et le bestiaire sont suffisamment solides.

---

# 58. OBJECTIF FINAL POUR LE CODE

L'objectif n'est pas simplement que le jeu respecte mécaniquement cette liste.

Le résultat doit donner l'impression suivante :

**je lance une run rapidement → je combats immédiatement → je commence à construire un build → l'Alambic transforme ce build → mes synergies deviennent progressivement absurdes → je profite réellement de cette puissance → même si je meurs j'ai gagné quelque chose → je peux immédiatement décider de retenter ou d'améliorer mon compte.**

Le projet existant doit évoluer vers cette boucle progressivement.

**Préserver le jeu existant partout où cela reste compatible avec cette vision.**
