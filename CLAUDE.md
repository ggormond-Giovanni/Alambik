# Alambic — conventions du dépôt

Roguelite de tir vue de dessus, portrait, Android. Godot 4.7.1, GDScript.
La spec vit dans `docs/superpowers/specs/`, le plan dans `docs/superpowers/plans/`,
l'état courant dans `ETAT.md`, l'historique dans `JOURNAL.md`.

## Règles qui ne se négocient pas

- **Godot 4.7.1** : `~/Téléchargements/Godot_v4.7.1-stable_linux.x86_64`.
- **Identifiants et commentaires en français sans accents.** Les textes affichés
  au joueur gardent leurs accents (`"Flèche double"`, pas `"Fleche double"`).
- **Les commentaires disent pourquoi, pas quoi.**
- **Aucune valeur d'équilibrage en dur dans la logique.** Tout vit dans
  `data/reglages.gd` ou dans un catalogue de `data/`.
- **`./verifier.sh` après chaque modification.** Le code de sortie ne suffit
  pas : le script greppe `SCRIPT ERROR` et charge tous les scripts et scènes,
  parce qu'une erreur de compilation dans un fichier qu'aucun test ne sollicite
  laisse un harnais naïf tout vert.
- **Aucun chiffre de performance ou d'équilibrage annoncé sans mesure.**
- **Rien qui vienne d'un jeu existant** : aucun nom, texte, icône, sprite ou son
  repris. Le son est synthétisé au démarrage, aucun fichier audio dans le dépôt.
- **Repli géométrique** : le jeu doit pouvoir tourner de bout en bout sans un
  seul sprite. Les sprites de `assets/characters/` sont un plus, pas un socle ;
  un `preload` dur sur un PNG absent casse le lancement, et c'est exactement ce
  que cette règle interdit.

## Pièges GDScript rencontrés ici

- `lerp`, `clamp`, `max`, `abs` renvoient du `Variant` : utiliser `lerpf`,
  `clampf`, `maxf`, `maxi`, `absf` dans les `:=`.
- Itérer sur une clé de `Dictionary` donne du `Variant` : `var m: PackedStringArray = (cle as String).split("+")`,
  jamais `var m := cle.split("+")`.
- Ne jamais modifier un tableau pendant qu'on l'itère : parcourir à rebours.
- Une erreur d'exécution interrompt la fonction courante **et** ses appelantes :
  `tests/lanceur.gd` a une ceinture de sécurité dans `_process` pour ne pas
  tourner en silence si `_initialize` meurt en route.
- Les requêtes de rayon lancées depuis `_process` renvoient des résultats vides.
  Pour les blocs de la salle, on utilise `Geometrie.ligne_libre`, qui se teste.

## Les deux boucles

- `./lancer.sh` — fenêtre au ratio du téléphone, souris émulant le doigt.
  Arguments utiles : `-- --salle=10 --dote=7 --graine=42 --auto`.
- `./deploy.sh` — export APK, `adb install`, lancement, logcat. C'est la seule
  boucle qui dit la vérité sur le pouce, la lisibilité et les performances.

## Vérifier

```sh
./verifier.sh            # tests + SCRIPT ERROR + cohérence des données
./sondes/vingt_runs.sh   # vingt runs headless pilotées par le bot
```

Lire les lignes de la sonde, pas seulement son code de sortie : vingt runs qui
s'arrêtent toutes page 3 signalent un blocage, pas une difficulté.
