# Alambic — conception de la V1

*Nom de travail. Dépôt : `RogueHero`. Date : 2026-08-01.*

## Ce qu'on fait

Un roguelite de tir vue de dessus pour Android, en portrait, jouable à une main,
par sessions de cinq à sept minutes. Le genre est celui d'Archero ; l'exécution,
l'univers et la mécanique centrale sont à nous.

La V1 est une **tranche verticale** : une run complète et honnête, du menu à la
mort, avec la mécanique signature entièrement fonctionnelle. Son rôle est de
répondre à une seule question — la fusion de compétences est-elle amusante ? —
avant qu'on investisse dans du contenu.

## Ce qu'on ne fait pas

Explicitement hors périmètre, à ne pas réintroduire en cours de route :

- méta-progression, équipement persistant, monnaie, boutique ;
- publicité, achats intégrés, tout SDK tiers, toute collecte de données ;
- second monde, second personnage, modes de jeu alternatifs ;
- export iOS ;
- musique et sprites définitifs (voir « Repli géométrique »).

## Univers

Une alchimiste descend dans un grimoire vivant. Chaque salle est une page ; les
ennemis sont des créatures d'encre, de plume et de verre brisé. La progression
se lit comme un livre qu'on feuillette.

Ce thème est choisi pour une raison fonctionnelle : il rend la fusion évidente
sans texte explicatif. Mélanger deux réactifs dans un alambic est un geste que
personne n'a besoin de se faire expliquer.

Palette : fonds parchemin sombres, ennemis en encre, projectiles en éclats
saturés. Contrainte de lisibilité : ce que le joueur doit éviter est toujours
plus clair et plus saturé que le fond.

## Boucle de jeu

```
Menu → Salle de combat → (2-3 vagues) → porte → draft d'un réactif parmi 3
     → ... → Alambic (fusion) → ... → Boss → écran de fin → Menu
```

Une run compte dix salles :

| Salle | Contenu |
|---|---|
| 1-4 | combat, puis draft |
| 5 | alambic |
| 6-8 | combat, puis draft |
| 9 | alambic |
| 10 | boss |

Le joueur ramasse sept réactifs et en dépense quatre en deux fusions : il finit
avec trois réactifs et deux essences. La mort renvoie au menu sans rien
conserver, hors meilleur résultat local.

## Contrôles

Joystick virtuel **flottant** : le pouce se pose n'importe où sur la moitié
basse de l'écran, l'origine du joystick naît sous le doigt. Le tir est
**automatique dès l'arrêt**, dirigé vers l'ennemi le plus proche. Aucun autre
bouton pendant le combat.

C'est la grammaire du genre. Elle n'est pas protégeable, elle est éprouvée, et
elle est ce qui permet de jouer d'une main.

## La signature : la fusion

### Principe

Une compétence est un **réactif**. À la salle 5 et à la salle 9, un alambic
propose de choisir **deux réactifs de son inventaire** : ils disparaissent et
deviennent une **essence**, une compétence unique qu'aucun draft ne peut donner.

La décision appartient au joueur — c'est le moment de jeu intéressant. Sacrifier
deux effets connus contre un effet plus fort, en sachant ce qu'on a déjà et ce
qu'on espère encore tirer.

Si le joueur possède les deux composants d'une recette, le draft peut proposer
directement l'essence, signalée comme telle par son cadre et son icône. Cela
donne un second chemin vers les fusions sans retirer la décision à l'alambic.

Deux réactifs sans recette commune ne peuvent pas être sélectionnés ensemble :
l'interface le montre avant le clic, elle ne punit pas après.

Trois règles pour lever toute ambiguïté :

- **Une essence ne peut pas servir de composant.** Pas de fusion de fusion en
  V1 ; c'est une explosion combinatoire qu'on n'a aucune raison de payer
  maintenant.
- **On peut quitter l'alambic sans fusionner.** Garder quatre réactifs modestes
  est un choix légitime, et la salle ne doit jamais se transformer en péage.
- **Tous les réactifs n'entrent pas dans une recette.** Fiole de vie n'en a
  aucune : c'est un réactif purement défensif qu'on garde ou qu'on ignore. Le
  joueur n'a pas à supposer que tout se combine.

### Structure de données

Un réactif n'est pas du code. C'est une ressource contenant :

- un identifiant, un nom, une description ;
- des modificateurs de statistiques (cadence, dégâts, vitesse, PV…) ;
- une liste de **comportements** appliqués au projectile ou au héros.

Une essence est une ressource de la même forme : elle n'est pas un cas
particulier, juste un réactif qu'on ne peut obtenir que par fusion.

La table des recettes est une **donnée unique** — une paire non ordonnée, une
essence. Aucune autre liste ne décrit les fusions ; deux listes finiraient par
diverger.

Le projectile est générique et exécute la liste de comportements qu'on lui
attache. Une fusion produit donc une composition de comportements, jamais du
code spécial dispersé dans le combat.

### Les quinze réactifs de la V1

Tir : Flèche double (+1 projectile), Ricochet (un rebond), Perforation
(traverse un ennemi), Braise (brûlure sur la durée), Givre (ralentit), Foudre
(chaîne vers un ennemi proche), Acide (la cible subit plus de dégâts), Éclat de
verre (se fragmente à l'impact).

Statistiques : Main leste (+cadence), Encre lourde (+dégâts, projectile plus
lent), Pas de chat (+vitesse), Fiole de vie (+PV max et soin), Œil de lynx
(projectile plus rapide et plus loin).

Utilitaires : Bouclier de sel (absorbe un coup, se recharge à chaque salle),
Sillage (laisse une traînée ralentissante quand on se déplace).

### Les dix recettes de la V1

| Réactifs | Essence | Effet |
|---|---|---|
| Ricochet + Braise | Traînée d'étincelles | chaque rebond laisse une flaque de feu |
| Flèche double + Éclat de verre | Volée d'échardes | l'impact projette cinq fragments |
| Givre + Encre lourde | Marteau de glace | projectile lent et lourd, gèle brièvement |
| Foudre + Acide | Circuit corrosif | la chaîne applique l'acide et porte plus loin |
| Perforation + Foudre | Lance d'orage | trait traversant qui électrise toute la ligne |
| Braise + Acide | Vapeur mordante | nuage persistant à la mort de l'ennemi |
| Givre + Sillage | Piste de gel | la traînée gèle au lieu de ralentir |
| Main leste + Flèche double | Rafale d'alambic | courte rafale de trois tirs |
| Bouclier de sel + Givre | Aura de cristal | le bouclier brisé explose en éclats gelants |
| Pas de chat + Œil de lynx | Tir en course | on tire en se déplaçant, à cadence réduite |

La dernière brise volontairement la règle du genre : c'est ce qu'on veut d'une
essence, qu'elle change la façon de jouer et pas seulement les chiffres.

## Adversaires

Quatre archétypes, chacun posant un problème différent :

- **Encrier rampant** — mêlée lente, arrive en groupe. Apprend à reculer.
- **Plume-sentinelle** — tireur immobile, tir télégraphié. Apprend à s'abriter.
- **Tache véloce** — charge en ligne droite après une préparation visible.
  Apprend à se déplacer perpendiculairement.
- **Scribe essaimeur** — reste au loin et fait apparaître des rampants. Apprend
  à choisir sa cible.

Le boss, **Le Correcteur**, tient en deux phases : barrage de traits d'encre en
motifs lisibles, puis invocations et charges. Il n'introduit aucune mécanique
que le joueur n'a pas déjà rencontrée.

## Salles

Arène fixe fermée, plus haute que large, avec quelques obstacles bloquant les
projectiles. Deux à trois vagues déclenchées à la mort de la précédente. La
porte s'ouvre quand la salle est vide.

Les compositions de vagues sont des données, pas du code.

## Architecture

Godot 4.7.1, GDScript, rendu 2D.

**Autoloads** — `Jeu` (état de la run : inventaire, salle courante, statistiques),
`Sons`, `Reglages` (options et meilleur résultat), `Ecran` (safe area Android).

**Scènes** — `Menu`, `Run` (orchestrateur qui enchaîne les salles), `Salle`,
`Heros`, `Ennemi` (base commune, variantes définies en données), `Projectile`
(générique, piloté par ses comportements), `UI/Joystick`, `UI/Draft`,
`UI/Alambic`, `UI/FinDeRun`.

**Données** — `data/reactifs/*.tres`, `data/recettes.gd`, `data/ennemis/*.tres`,
`data/salles/*.tres`, `data/reglages.gd` pour l'équilibrage global.

Chaque unité doit pouvoir s'expliquer en une phrase et se tester seule. Un
fichier qui grossit est le signe qu'il fait deux choses.

**Résolution** — viewport de référence 1080×1920, étirement `canvas_items` en
`keep_width` : la largeur est garantie, la hauteur visible varie avec le ratio
de l'appareil. L'arène se conçoit donc sur la largeur, et l'interface respecte
la safe area.

**Aucune valeur d'équilibrage en dur au milieu de la logique.** Cadence, dégâts,
PV, durées, vitesses : tout vit dans les données. Régler le jeu ne doit jamais
demander de relire le code du combat.

## Repli géométrique

Le jeu tourne du premier jour à la V1 sans un seul sprite : héros, ennemis et
projectiles sont des formes géométriques colorées. Une banque de sprites les
remplace quand les images existent, avec repli automatique quand elles
manquent.

L'art ne doit jamais bloquer le jeu.

## Outillage et itération

Deux boucles distinctes, c'est le point le plus important de cette section.

**Boucle rapide — PC.** `./lancer.sh` ouvre le jeu dans une fenêtre au ratio du
téléphone, avec l'émulation tactile de la souris. C'est là que se font la
majorité des allers-retours : équilibrage, comportements, interface.

**Boucle de vérité — téléphone.** `./deploy.sh` enchaîne export APK debug,
`adb install -r`, lancement, puis `adb logcat` filtré. Elle sert à ce que le PC
ne peut pas dire : confort du pouce, lisibilité, performances réelles, safe
area. ADB sans fil pour éviter le câble.

**Ordre de construction.** La chaîne de déploiement se valide avant le
gameplay : premier lot = projet portrait vide, un carré qui suit le joystick
flottant, installé sur l'appareil de test. Si la chaîne casse, elle casse sur
cinquante lignes.

État de la chaîne au moment d'écrire : JDK 17 et SDK Android présents sur la
machine, templates d'export Godot 4.7.1 et keystore de debug à mettre en place.

## Vérification

Rien ne s'annonce sans mesure. En particulier, aucun chiffre d'équilibrage ou de
performance donné à vue.

- **Sonde headless avec bot** (`--auto`) : fait tourner des runs entières sans
  intervention, pour détecter les blocages, les crashs et les fusions cassées.
- **Assertions** (`--selftest`) : toute recette pointe vers des réactifs
  existants, tout réactif porte au moins un effet, aucune référence morte, la
  table des recettes ne contient pas deux fois la même paire.
- Le code de sortie ne suffit pas : toujours grepper `SCRIPT ERROR` en plus,
  car une erreur de compilation dans un script non sollicité laisse le harnais
  vert.

## Critères d'acceptation de la V1

1. L'APK debug s'installe et se lance sur l'appareil de test.
2. Une run complète — menu, dix salles, deux alambics, boss, écran de fin — est
   jouable au doigt de bout en bout.
3. Les quinze réactifs et les dix recettes fonctionnent, et les essences ont un
   effet observable distinct de leurs composants.
4. Vingt runs du bot headless s'achèvent sans crash ni blocage.
5. `--selftest` passe et aucun `SCRIPT ERROR` n'apparaît.
6. Les performances sur l'appareil de test sont mesurées et consignées — pas
   estimées.

## Droit d'auteur

Les mécaniques de jeu ne sont pas protégeables ; les expressions le sont. Donc :

- aucun nom de compétence, texte, icône, son ou sprite repris d'un jeu existant ;
- interface dessinée à partir du besoin, jamais décalquée écran par écran ;
- le nom « Archero » n'apparaît nulle part dans le projet, le dépôt, les
  métadonnées ou la fiche du store ;
- le nom définitif est vérifié sur les registres de marques avant publication.
  « Alambic » est un nom de travail et n'a pas encore été vérifié.

## Risques identifiés

**L'équilibrage combinatoire.** Dix recettes, c'est dix cas particuliers à
régler. Atténuation : les essences se composent de comportements existants, et
le bot headless permet de faire tourner beaucoup de runs sans jouer.

**Le feel du tir automatique.** S'il est mou, tout le reste est inutile.
Atténuation : il fait partie du premier lot, avant tout contenu.

**Le format portrait.** Il contraint l'arène et l'interface. Décision assumée :
c'est ce qui rend le jeu jouable d'une main, donc jouable tout court.
