# scripts/run/

`run.gd` est l'orchestrateur principal et reste volontairement gros pour l'instant. Ne pas le lire en entier pour une petite tâche : chercher d'abord le signal, la fonction ou la chaîne concernée et lire une plage ciblée.

Il doit coordonner les systèmes, pas devenir leur implémentation. Si une nouvelle fonctionnalité autonome dépasse quelques fonctions, préférer un module dédié dans le domaine correspondant.
