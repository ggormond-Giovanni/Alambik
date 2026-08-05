# Mettre Alambic sur le téléphone

Tout est déjà installé et configuré sur cette machine : templates d'export
Godot 4.7.1, SDK Android, JDK 17, keystore de debug. L'APK a déjà été produit
une fois (`build/alambic.apk`, 28,6 Mo). Il ne reste que le téléphone.

## 1. Préparer le téléphone (une fois)

1. **Réglages ▸ À propos du téléphone** — taper sept fois sur *Numéro de build*.
   Un message confirme que le mode développeur est actif.
2. **Réglages ▸ Système ▸ Options pour les développeurs** — activer
   **Débogage USB**. Si le téléphone est en Android 11 ou plus et que tu veux
   éviter le câble, activer aussi **Débogage sans fil**.
3. Facultatif mais utile : activer **Rester activé** (l'écran ne s'éteint pas
   pendant que le téléphone est branché).

## 2. Relier le téléphone

### Par câble (le plus simple)

Brancher le câble, puis sur le PC :

```sh
~/Android/Sdk/platform-tools/adb devices
```

Le téléphone affiche une demande d'autorisation : cocher « Toujours autoriser »
et accepter. La commande doit alors lister l'appareil avec l'état `device`.
S'il affiche `unauthorized`, l'autorisation n'a pas été acceptée.

### Sans fil (Android 11+)

Sur le téléphone : *Options pour les développeurs ▸ Débogage sans fil ▸
Associer l'appareil avec un code*. Il affiche une adresse `ip:port` et un code
à six chiffres. Sur le PC :

```sh
~/Android/Sdk/platform-tools/adb pair 192.168.1.42:37000     # adresse et port d'association
~/Android/Sdk/platform-tools/adb connect 192.168.1.42:35000  # adresse et port de la page principale
```

Attention : le port d'**association** et le port de **connexion** sont
différents, et ils changent à chaque fois. Le PC et le téléphone doivent être
sur le même réseau Wi-Fi.

## 3. Installer et lancer

Depuis le dépôt :

```sh
./deploy.sh
```

Le script exporte l'APK, l'installe, lance le jeu, puis affiche les logs du
téléphone (`Ctrl-C` pour sortir — le jeu continue de tourner). S'il ne voit
aucun appareil, il le dit et rappelle les commandes ci-dessus.

Pour ne pas rester dans les logs :

```sh
./deploy.sh --sans-logs
```

## 4. Installer sans le PC (envoi du fichier)

L'APK est autonome. Tu peux l'envoyer par mail, le déposer sur un cloud ou le
copier par câble :

```sh
~/Android/Sdk/platform-tools/adb push build/alambic.apk /sdcard/Download/
```

Sur le téléphone, ouvrir le fichier depuis *Fichiers ▸ Téléchargements*.
Android demandera d'autoriser l'installation d'applications de cette source :
c'est normal pour un APK qui ne vient pas du Play Store. L'APK est signé avec
une clé de debug, donc utilisable pour tester, mais pas publiable en l'état.

## 5. Ce qu'il faut regarder sur l'appareil

Le PC ne sait rien dire de ces quatre points — c'est pour ça que la boucle
téléphone existe :

- **Le pouce.** Poser le pouce n'importe où sur la moitié basse doit suffire.
  Si tu dois viser une zone, le joystick flottant est mal réglé
  (`JoystickLogique.RAYON`, `ZONE_MORTE` dans `scripts/joystick_logique.gd`).
- **La lisibilité.** Les créatures d'encre doivent trancher sur le parchemin,
  et les traits rouges des sentinelles doivent se voir avant d'arriver.
- **La safe area.** Rien d'important ne doit passer sous l'encoche ni sous la
  barre de navigation (`autoload/ecran.gd`).
- **Les images par seconde**, surtout page 8 et pendant les barrages du boss.
  Aucun chiffre n'est annoncé tant qu'il n'a pas été mesuré là.

Note ce que tu observes dans `ETAT.md`, section « Mesures relevées » : elle est
volontairement vide pour ces lignes.

## En cas de problème

| Symptôme | Cause probable |
|---|---|
| `adb devices` ne liste rien | câble en mode « charge seule », ou débogage USB non activé |
| `unauthorized` | la fenêtre d'autorisation n'a pas été acceptée sur le téléphone |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | une version signée d'une autre clé est déjà installée : `adb uninstall com.giovanni.alambic` |
| L'application se ferme au lancement | lire `adb logcat godot:V GodotEngine:V "*:S"` : une erreur GDScript s'y voit |
| L'export échoue sur le keystore | vérifier `export/android/debug_keystore` dans `~/.config/godot/editor_settings-4.7.tres` |
