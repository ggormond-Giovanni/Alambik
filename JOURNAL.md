# Journal — Alambic

Historique des décisions et des mesures. Jamais lu automatiquement ; on vient y
chercher pourquoi une chose est comme elle est.

## 2026-08-11 — Première tranche de la refonte `design.txt`

La boucle historique de trente salles et de fusions destructrices a été
remplacée sans reconstruire le combat. Une run de campagne contient maintenant
vingt salles, six choix aux paliers 2/4/7/9/14/19 et trois Alambics après
4/9/14. L'Alambic tire un Élément, puis ajoute sa transformation à l'Augment
choisi : l'original reste dans l'inventaire et continue de fonctionner.

Les dix thèmes existants servent désormais de mondes, chacun décliné en trois
chapitres. C'est volontairement une structure avant d'être une promesse de
contenu : bestiaire, décors et boss restent réutilisés tant que leurs variantes
propres ne sont pas produites. Le troisième chapitre est déjà identifié comme
porteur du boss signature.

Le coffre de run progresse aux paliers 5/10/15/20, survit à la défaite et
retourne automatiquement au menu après révélation. Les Grands coffres possèdent
une garantie d'objet après cinq échecs. Les Épreuves existantes sont devenues
cinq miniboss consécutifs.

Mesure : `./verifier.sh` charge tout le projet et termine avec 25 suites,
9 058 assertions, 0 échec et aucun effet déclaré mais inerte. Un smoke test
headless a traversé le premier draft et le premier Alambic : l'inventaire passe
de l'Augment original à original + nouvel Augment + Fusion, ce qui confirme que
rien n'est consommé.

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
## 2026-08-07 — Musique adaptative et fluidité

Le jeu n'avait aucune musique : huit balayages synthétiques très courts
constituaient toute la trame sonore. Trois couches stéréo originales sont
maintenant synthétisées au démarrage sur une même grille harmonique : ambiance,
combat et boss. Elles restent synchronisées et se fondent selon l'écran et le
nombre de menaces, tandis que les drafts et la fin de run ramènent le calme.

Le héros passe désormais par une accélération et un freinage courts, avec une
inclinaison et une compression visuelles qui ne touchent pas sa collision. Les
projectiles rapides utilisent l'interpolation physique afin de rester continus
sur un écran à rafraîchissement élevé. Le test en situation a également montré
que les fragments étaient créés pendant le traitement d'une collision ; leur
création est maintenant différée, supprimant les erreurs et saccades associées.

Mesure locale : les trois boucles stéréo de dix secondes sont produites en moins
d'une seconde sur la machine de développement. Cette durée et le mix restent à
mesurer sur Android. `./verifier.sh` : 17 suites, 3 220 assertions, 0 échec,
aucun `SCRIPT ERROR`.

### Spritesheets et interface moderne

Trois planches originales remplacent les images fixes : huit frames de course
et d'attaque pour l'alchimiste, quatre frames pour chacun des quatre ennemis,
et huit frames de flottement et d'attaque pour le boss. Elles sont découpées à
l'exécution, sans créer un noeud par frame. Leur chargement reste optionnel :
les replis géométriques reprennent la main si un PNG manque.

L'interface repose maintenant sur `StyleInterface` : panneaux arrondis, ombres,
bordures lumineuses, états de survol/appui, transitions d'entrée et grandes
cibles tactiles cohérentes. Le langage est appliqué au menu, au HUD, au joystick,
aux cartes, au draft, à l'alambic et à l'écran de fin. La couche musicale calme
a aussi reçu une ligne aérienne lente au-dessus de son pad et de son arpège.

Retour de jeu suivant : l'ancrage vertical différait entre la ligne de course et
celle de tir. Chaque ligne a maintenant sa propre compensation, la taille du
héros a été réduite, sa vitesse portée à 500 et l'arène élargie en supprimant une
marge latérale redondante. Les réserves haute et basse ont aussi été resserrées.

### Arène et hiérarchie de combat

La référence visuelle fournie a servi pour la structure, pas pour ses assets :
arène centrale carrelée, limites décoratives, objectif spatial en haut et HUD en
trois blocs. L'interprétation reste celle d'Alambic, plus sombre et minérale,
avec mousse magique, pierres d'encre, sceau alchimique et portail de grimoire.
La vie est désormais attachée au mage ; le haut affiche pause, page et nombre de
réactifs. Le bouton ouvre une vraie pause qui conserve exactement la salle.

## 2026-08-11 — Scaling long, portails et Mine de survie

L'arbre court ne pouvait pas porter trente chapitres. Il compte désormais trente
Maîtrises, dix par branche, avec des paliers offensifs, défensifs et utilitaires
qui vont du petit bonus au multiplicateur de fin de campagne. Les coffres suivent
une courbe de Gouttes par chapitre : le revenu moyen de trente Grands coffres
dépasse le coût de l'arbre complet sans atteindre une fois et demie ce coût. La
montée mondiale des PV a été resserrée et le premier miniboss reste sous 1 000 PV
dans toutes ses variantes testées.

Une salle nettoyée ne téléporte plus le héros. Elle ouvre un portail physique,
animé et sonore ; le signal de fin ne part qu'à sa traversée. Le bot de sonde
emprunte exactement le même trajet que le joueur.

La Mine est devenue une survie de cinq minutes dans une arène agrandie par une
caméra à 68 %. Le plafond, la fréquence, les PV et les dégâts montent avec le
temps ; les Scribes n'entrent qu'en seconde moitié et leurs invocations respectent
le plafond. Chaque créature donne de l'XP et chaque niveau rend 30 % des PV pour
remplacer les respirations absentes d'une arène unique. À 0:00 les apparitions
s'arrêtent, les survivants sont nettoyés, puis le boss combat seul. Smoke test :
425 éliminations, boss abattu, portail traversé, victoire à 5 min 19 s.

### Continuité des interfaces

Les écrans avaient chacun une entrée courte mais disparaissaient encore par
`queue_free` visible. Un langage commun gère maintenant entrée, sortie,
rafraîchissement et apparition en cascade, avec des durées raccourcies par le
réglage d'effets réduits. Il est appliqué aux menus, aux listes d'Arsenal, aux
Maîtrises, à l'Équipement, aux Réglages, au Draft, à l'Alambic, à la Pause et
aux récompenses. Les pages du menu glissent selon le sens de navigation.

Le début d'une run et chaque passage de portail utilisent un voile opaque à
sceau alchimique animé : fermeture, changement réel de salle, puis ouverture.
La couche intercepte les gestes pendant quelques dixièmes de seconde, ce qui
empêche aussi un déplacement ou un tir involontaire pendant le changement.

### Variété des miniboss et règles de Fusion

Les salles 5/10/15 pouvaient tirer plusieurs fois le même miniboss et leurs
identifiants partageaient malgré tout les mêmes patterns. Elles tournent
maintenant dans un roster de dix adversaires sans répétition consécutive ; les
Épreuves montrent cinq profils différents par tentative. Charges, invocations,
barrages, spirales, pluies et anneaux à brèche composent des répertoires propres,
complétés par dix ornements et sigils de combat.

Les trois Alambics tirent désormais sans remise parmi les six Éléments : aucun
Élément ne peut donc occuper toute une run. Une Fusion marque aussi son Augment
source. L'effet original reste actif, mais cet Augment disparaît des Alambics
suivants et toute tentative de seconde Fusion est refusée par la logique, pas
seulement masquée par l'interface.

### Corrections de comportements de combat

La Tache véloce rouge renvoyait `repos` tant que le héros se trouvait à plus de
900 pixels. Elle marche désormais vers sa cible à 45 % de sa vitesse de charge,
puis télégraphie et exécute sa ruée dès qu'elle entre dans sa zone d'attaque ;
son vrai temps de récupération est aussi respecté.

Salve était réglée à trois tirs malgré son intention de design : elle en produit
exactement deux. Enfin, Ricochet ne traite plus un mur comme une cible de
rebond. Tout mur termine immédiatement le projectile et interdit aussi la
création de fragments depuis l'intérieur de l'obstacle ; un verrou empêche un
second contact pendant la même image physique.

## 2026-08-11 — Bestiaire majeur et ouverture des coffres

Le catalogue compte désormais huit créatures communes, dix miniboss et dix
boss signatures. Les Folios orbitent, les Marges harcèlent à distance et les
Miroirs annoncent une onde radiale ; le Sceau-bélier reprend la charge avec une
préparation plus longue. Les rencontres introduisent ces contraintes par
étapes au lieu de seulement augmenter la densité.

Les salles 5/10/15 et la Mine ne tirent que dans le roster des miniboss. Les
chapitres 1 et 2 finissent également sur un miniboss, tandis que chaque
chapitre 3 possède un boss signature exclusif. Les vingt identités majeures
lisent leurs deux répertoires depuis le catalogue et combinent dix motifs :
murs à brèche, éventails, barrages croisés, spirale, anneau ouvert, pluie,
poursuite, charge annoncée, invocation plafonnée et pause. Les PV de base des
premiers adversaires ont été abaissés ; le premier palier reste sous 550 PV mis
à l'échelle et le premier boss de monde sous la cible de 7 000 PV.

Le coffre n'est plus une ligne de texte encadrée. Il tombe, rebondit, secoue son
verrou, soulève son couvercle, projette halo, faisceau et étincelles, puis révèle
Gouttes et équipement. Le retour automatique attend cette séquence uniquement
quand un coffre a réellement été gagné.

## 2026-08-13 — Silhouettes, signatures et fluidité

Les dix miniboss ne reposent plus sur le même corps recoloré. Chacun possède une
silhouette procédurale lisible sans sprite : rature dentelée, faute à trois
noyaux, masque correcteur, reliure-mâchoire, virgule, index, marge, enluminure,
signet et duo copiste. Leur première phase introduit aussi une attaque exclusive
parmi dix nouveaux motifs. Un anneau de préparation précède ces signatures et
une courte matérialisation empêche toute attaque dès l'image d'apparition.

Le bestiaire commun passe de huit à onze créatures. Le Cachet phaseur traverse
la cible après s'être effacé, le Fuseau tisseur ferme trois trajectoires
parallèles et la Fiole volatile gonfle avant une explosion radiale. Leurs
décisions restent pures dans `Cerveaux`, leurs chiffres vivent dans le catalogue
et les rencontres tardives les mélangent aux contraintes existantes.

Les apparitions aspirent maintenant des éclats vers leur centre. Les boutons
s'enfoncent et reviennent avec un léger rebond ; les onglets interpolent leur
élévation, leur couleur et leur indicateur. Le mode « Effets réduits » conserve
des versions plus brèves et plus discrètes de ces mouvements.

### Passe professionnelle sur les menus

Les écrans n'assemblent plus chacun leur propre imitation du même fond. Un
langage partagé dessine profondeur verticale, halos retenus, sceaux lents,
coins de cadre et en-têtes à trois niveaux. Les accents restent contextuels :
or pour la campagne et l'équipement, essence pour les réglages et la pause,
couleur de branche ou de capacité pour les catalogues.

Les contrôles secondaires ont rejoint le niveau des actions principales :
sélecteurs d'équipement et leur menu déroulant, options d'accessibilité,
curseurs, états désactivés et panneaux de section ont maintenant des contrastes
et surfaces dédiés. Le menu principal possède un vrai socle de navigation et
une carte de profil, sans retirer de place aux cibles tactiles.

Les changements de mode de descente glissent désormais dans leur direction,
les catégories de l'Arsenal sortent avant que les suivantes entrent, et les
cartes d'Équipement apparaissent en cascade. L'ouverture d'un grimoire combine
bandes de pages, sceau, particules et rail de progression ; le voile entre les
salles reprend le même vocabulaire. Les captures téléphone du menu, des
Réglages, de la sélection, de l'Équipement, de l'Arsenal, de la Maîtrise, de la
Pause et de la transition ont servi à corriger marges et lisibilité.

### Prototype jouable 16-bit

La sélection de descente propose maintenant une quatrième entrée expérimentale.
Elle lance une salle courte en trois vagues, terminée par La Rature, avec les
mêmes commandes et la même musique que le jeu principal. Ce mode ne touche pas
à la progression persistante : pas d'XP de compte, de résultat annexe ou de
récompense.

Le décor, l'alchimiste, les créatures, le miniboss, les projectiles et les
particules possèdent un rendu procédural sur grille de quatre pixels. La palette
est resserrée, les silhouettes sont faites de blocs francs et les poses changent
par paliers pour tester une sensation 16-bit sans produire prématurément tout un
atlas de sprites. Une bordure dédiée et un HUD « STAGE 1 • 16-BIT » rendent le
prototype immédiatement identifiable.

Validation : 23 suites, 7 997 assertions sans échec ; une partie automatique a
nettoyé les trois vagues, vaincu le miniboss et traversé le portail en 18 secondes.

## 2026-08-13 — Le prototype devient la direction finale

Le rendu 16-bit n'est plus une quatrième descente expérimentale. Il couvre la
campagne, la Mine, les Épreuves, le menu, les transitions, le HUD et les effets.
Le héros, les onze créatures communes, les dix miniboss et les dix signatures
sont dessinés sur une grille de quatre pixels avec poses discrètes et silhouettes
propres. Les panneaux ont perdu leurs arrondis, l'interface adopte une police
monospace et le filtrage global privilégie les contours nets.

Les anciennes illustrations et planches ont été sorties du dépôt et conservées
dans `Documents/Alambic_assets_peints_2026-08-13`, avec l'ancienne icône moderne.
L'icône active est désormais une cornue en blocs originale.

Deux compositions peuvent être choisies dans les Réglages : First Arcade et
Dynamic Arcade. Le choix est sauvegardé et le lecteur de combat recharge la
piste immédiatement sans toucher au volume des effets.
