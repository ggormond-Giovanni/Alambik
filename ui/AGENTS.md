# ui/

Écrans et contrôles. Réutiliser `InterfaceMobile`, `StyleInterface`, `Retro16`, `Palette` et `Polices` au lieu de recréer un langage visuel par écran.

## Règle mobile

L'interface est composée en couches indépendantes :

1. fond décoratif recadré avec conservation du ratio ;
2. ornements visuels sans information indispensable ;
3. vrais `Control` Godot pour textes, boutons, listes et panneaux.

Ne jamais étirer une image pour l'adapter au ratio du téléphone. Ne jamais graver dans un PNG un texte, une valeur, un bouton ou une zone qui doit rester interactive. Utiliser `Container`, anchors et `Ecran.marge_haute()/marge_basse()` pour la mise en page.

Pour une tâche locale, ouvrir le `.gd` et le `.tscn` du même écran uniquement. Le gameplay ne doit pas être implémenté dans l'UI.
