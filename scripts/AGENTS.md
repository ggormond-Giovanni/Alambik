# scripts/

Lire `scripts/INDEX.md`, puis le `AGENTS.md` du sous-dossier ciblé. Chercher les symboles avant d'ouvrir les gros fichiers.

La logique consomme `data/` et ne possède pas sa propre copie des chiffres. Garder les dépendances entre domaines explicites ; éviter d'ajouter une nouvelle responsabilité à `run/run.gd`, aux gros acteurs ou au menu lorsqu'un module local suffit.
