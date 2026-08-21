# État courant — résumé de travail

Ce fichier sert à s'orienter, pas à remplacer les données du jeu. Pour une valeur exacte, lire le catalogue ou `data/reglages.gd` concerné.

## Jouable

- Campagne structurée en mondes, chapitres et salles, avec miniboss et boss.
- XP de run, choix d'Améliorations et fusions élémentaires via les Alambics.
- Équipement, Forge et progression permanente.
- Mine de survie et Épreuves rituelles.
- Sort actif, Passif(s) et Ultime équipables.
- Interface portrait mobile, joystick/tactile, réglages, pause et navigation paginée.
- Sondes headless et suites de tests maison.

## Architecture de données

Les chiffres et catalogues sont centralisés dans `data/` : réglages généraux, Améliorations, Éléménts, ennemis, objets, chapitres, vagues, récompenses, sorts et Maîtrises. La logique doit consommer ces données au lieu de créer une deuxième source de vérité.

## Points encore ouverts

- Identité environnementale et bestiaire propres à chaque monde.
- Variantes et polissage final des boss.
- Effets finaux de certains équipements et migration d'anciens objets.
- Ajustement fin de l'économie et des paliers des modes annexes.
- Identité finale de certaines transformations élémentaires.
- Contrôle mobile définitif et post-game.
- Découpage progressif des plus gros contrôleurs lorsque leur modification l'exige réellement.

## Vérification

L'état historique détaillé et les anciennes mesures ont été conservés dans `docs/archive/ETAT_2026-08-14.md`. Elles ne doivent pas être considérées comme des mesures actuelles sans relancer les outils.

Pour vérifier l'état présent :

```sh
./verifier.sh
./sondes/vingt_runs.sh
```
