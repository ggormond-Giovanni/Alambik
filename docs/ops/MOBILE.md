# Mettre Alambic sur le téléphone

Ce guide décrit la configuration Linux de la machine de développement d'origine : Godot 4.7.1, SDK Android, JDK 17 et keystores. Sur un nouveau PC, ces dépendances doivent être configurées avant d'utiliser les scripts `.sh`.

## Préparer le téléphone

1. Réglages ▸ À propos du téléphone — taper sept fois sur *Numéro de build*.
2. Réglages ▸ Système ▸ Options pour les développeurs — activer **Débogage USB**. Android 11+ permet aussi le débogage sans fil.
3. Facultatif : activer **Rester activé** pendant le branchement.

## Relier le téléphone

Par câble :

```sh
~/Android/Sdk/platform-tools/adb devices
```

Accepter l'autorisation sur le téléphone ; l'état attendu est `device`.

Sans fil :

```sh
~/Android/Sdk/platform-tools/adb pair IP:PORT_ASSOCIATION
~/Android/Sdk/platform-tools/adb connect IP:PORT_CONNEXION
```

Les deux ports sont différents et peuvent changer.

## Installer et lancer

```sh
./deploy.sh
./deploy.sh --sans-logs
```

`deploy.sh` exporte, installe, lance puis peut afficher les logs. Pour une version de distribution :

```sh
./publier.sh
./publier.sh 0.2
```

`publier.sh` lance `./verifier.sh` avant l'export.

## Signature

La clé de release et ses identifiants restent hors du dépôt. Sauvegarder la clé : sa perte empêche de publier une mise à jour acceptée par les installations existantes. Une APK debug et une APK release signées différemment ne se remplacent pas directement.

## Contrôles sur appareil

- Pouce : la moitié basse doit suffire pour piloter. Logique : `scripts/entrees/joystick_logique.gd`.
- Lisibilité : silhouettes et télégraphes doivent rester visibles en mouvement.
- Safe area : `autoload/ecran.gd`.
- Performances : mesurer sur téléphone avant d'annoncer un chiffre.

Noter les observations actuelles dans `docs/CURRENT.md` ou dans un document de mesure dédié ; ne pas gonfler l'index de travail avec un journal chronologique.

## Problèmes fréquents

| Symptôme | Cause probable |
|---|---|
| `adb devices` ne liste rien | câble en charge seule ou débogage USB inactif |
| `unauthorized` | autorisation non acceptée sur le téléphone |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | signature différente ; désinstaller l'ancienne version |
| fermeture au lancement | lire `adb logcat godot:V GodotEngine:V "*:S"` |
| export impossible | vérifier la configuration Android/keystore de Godot |
