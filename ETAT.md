# État — Alambic

*Mis à jour le 2026-08-05.*

La V1 est jouable de bout en bout : menu, **trois chapitres de cinquante pages**,
quatre alambics et un mi-chapitre par chapitre, un boss propre à chacun, écran
de fin. Elle tourne sur PC et s'exporte en APK Android signé. Ce qui manque est
listé plus bas, sans arrondi.

## Où chercher quoi

| Je veux… | C'est ici |
|---|---|
| régler PV, dégâts, cadence, durées, tailles d'arène | `data/reglages.gd` — **seule** source d'équilibrage |
| ajouter ou modifier un réactif | `data/catalogue_reactifs.gd` |
| ajouter ou modifier une essence | `data/catalogue_essences.gd` |
| changer une fusion | `data/recettes.gd` — source unique, paire triée → essence |
| régler un ennemi | `data/catalogue_ennemis.gd` |
| changer la composition d'une page | `data/vagues.gd` — paliers, pas cinquante listes |
| ajouter un chapitre, déplacer un alambic, régler la montée | `data/chapitres.gd` |
| chiffrer ce que vaut une main ou une fusion | `scripts/puissance.gd` |
| comprendre comment un réactif agit sur le tir | `scripts/mods.gd` puis `scripts/tir.gd` |
| toucher au comportement d'un ennemi | `scripts/cerveaux.gd` (décision pure) puis `scripts/ennemi.gd` (exécution) |
| toucher au boss | `scripts/boss.gd` |
| toucher au dessin d'une créature ou d'une icône | `scripts/dessin.gd` (formes) et `scripts/palette.gd` (couleurs) |
| toucher à l'enchaînement des pages | `scripts/run.gd` |
| toucher à une page de combat | `scripts/salle.gd` |
| toucher à l'interface | `ui/` : `hud.gd`, `draft.gd`, `alambic.gd`, `carte_reactif.gd`, `joystick.gd`, `fin_de_run.gd` |
| lancer sur PC | `./lancer.sh` |
| installer sur le téléphone | `./deploy.sh` (voir `MOBILE.md`) |
| produire l'APK à télécharger | `./publier.sh` → `dist/alambic.apk` |
| vérifier | `./verifier.sh` puis `./sondes/vingt_runs.sh` |
| voir l'équilibrage chiffré | `godot --headless --path . --script sondes/equilibrage.gd` |

Arguments de développement (après `--`) : `--graine=N` (run rejouable),
`--salle=N` (démarrer à une page), `--chapitre=N` (1 à 3), `--dote=N` (N réactifs
au départ), `--auto` (bot), `--bavard` (traces du bot),
`--capture=<fichier> --capture-apres=<s>`.

## Mesures relevées

Mesurées, pas estimées. Machine de développement, Godot 4.7.1, headless.

| Quoi | Valeur | Comment |
|---|---|---|
| Suites de tests | 15 suites, 522 assertions, 0 échec | `./verifier.sh` |
| Vingt runs du bot | 0 échec / 20 ; 18 atteignent la page 10, 1 victoire | `./sondes/vingt_runs.sh` |
| Taille de l'APK debug | 30 Mo (arm64-v8a seul, sprites inclus) | `ls -lh build/alambic.apk` |
| Taille de l'APK release | 28 Mo, signé `CN=Alambic` | `apksigner verify --print-certs` |
| Durée d'un export APK | 18,2 s | `/usr/bin/time` sur `--export-debug` |

**Non mesuré à ce jour : tout ce qui demande l'appareil.** Images par seconde
réelles, confort du pouce, lisibilité, durée d'une run jouée à la main, durée
d'un cycle `deploy.sh` complet. Aucun appareil n'était branché (`adb devices`
vide). Ces lignes restent vides tant que le téléphone n'a pas parlé.

## Critères d'acceptation de la spec

1. **APK debug s'installe et se lance** — *non vérifié* : l'APK est produit et
   signé (`build/alambic.apk`), mais aucun appareil n'était connecté.
2. **Run complète jouable au doigt** — *partiellement* : la run complète
   s'enchaîne (bot headless jusqu'au boss, 20/20), le pouce n'a pas été testé.
3. **Quinze réactifs, dix recettes, essences observables** — vérifié par les
   tests et par `sondes/selftest.gd`, qui échoue si un drapeau d'essence n'est
   lu par aucun script.
4. **Vingt runs headless sans crash ni blocage** — vérifié : 0 échec sur 20.
5. **`verifier.sh` vert, aucun `SCRIPT ERROR`** — vérifié.
6. **Performances mesurées** — *non fait*, faute d'appareil.

## Écarts assumés par rapport au plan

- Les réactifs sont un catalogue GDScript, pas des `.tres` (justifié dans le plan).
- `Reglages` est une classe de constantes, pas un autoload : les suites headless
  doivent lire l'équilibrage sans monter de SceneTree.
- Le héros appartient à `Run`, pas à `Salle` : ses PV et son inventaire doivent
  traverser les pages.
- Une essence prise au draft consomme ses composants, exactement comme à
  l'alambic : la fusion est un échange, jamais un cadeau.

## Équilibrage — ce qui a été mesuré et corrigé

Trois reproches de jeu, trois corrections, chacune chiffrée par
`sondes/equilibrage.gd` avant et après.

**Les fusions ne valaient pas leurs composants.** Trois essences sur dix étaient
plus faibles que les deux réactifs gardés séparément — Rafale d'alambic valait
0,56 fois ses composants. Elles ont été réécrites ; les dix passent maintenant,
avec une marge d'au moins 15 %, et `tests/test_puissance.gd` échoue si l'une
d'elles repasse sous la barre.

**Des combinaisons cassées.** La meilleure main sur cinq réactifs valait 2,35
fois la médiane et près de six fois la plus faible. Trois causes, toutes
corrigées : les multiplicateurs se composaient en produit (ils s'additionnent
désormais), les éclats frappaient à 45 % du tir d'origine (28 %), et un
projectile traversait quatre ennemis à pleine puissance (il perd 35 % par
traversée, 25 % par rebond). Écart ramené à **1,96×**, plafonné par un test.

**La difficulté s'effondrait sur cinquante pages.** À la page 50, le héros valait
16 fois ce que la page pouvait lui opposer. La montée des créatures est passée
d'une droite à une courbe géométrique (×16 en PV sur un chapitre), les copies
d'un même réactif rendent moins à chaque exemplaire, et le draft n'arrive plus
qu'une page sur deux. Rapport héros/créatures sur le premier chapitre : entre
1,0 et 2,5 du début à la fin.

## Décisions de conception prises pendant l'implémentation

- **Une fusion consomme toujours ses composants**, à l'alambic comme au draft.
  Prendre une essence sans rien perdre retirait tout son sel à la décision.
- **Un réactif se reprend, mais pas indéfiniment** : trois copies au plus, deux
  pour ceux qui ajoutent des projectiles ou des rebonds, une seule pour ceux qui
  ne posent qu'un effet — un second exemplaire de Braise n'ajouterait rien.
  Quand tout est au plafond, le draft offre une page de repos qui soigne.
- **Réserve d'encre finie** : un scribe essaimeur ne produit que six rampants sur
  sa vie, et personne n'invoque au-delà de dix ennemis présents. Sans cette
  borne, une page dont on ne prend jamais l'invocateur pour cible est infinie —
  la sonde l'a montré deux fois.
- **Tirs presque parallèles** plutôt qu'en éventail large : à 14°, les deux
  projectiles de Flèche double passaient de chaque côté d'un ennemi lointain.
- **Anticipation du tir** : on vise où la cible sera. Sans cela, un scribe qui
  recule survivait à trois cents projectiles.
- **Les blocs d'encre ne reçoivent pas d'ennemi** : une créature apparue dedans
  était intouchable.
- **Contournement** : ennemis et bot dévient quand ils n'avancent plus. Un
  ennemi qui pousse contre un bloc bloque la page pour toujours.

## Ce qui reste à faire

- Brancher un téléphone et remplir les mesures manquantes.
- Régler l'équilibrage une fois qu'un humain a joué : le bot meurt souvent au
  boss, ce qui ne dit rien de la difficulté ressentie.
- La musique et les sons sont synthétisés au démarrage, volontairement discrets.
  Rien de définitif : hors périmètre V1.
- Le nom « Alambic » n'a pas été vérifié sur les registres de marques.
