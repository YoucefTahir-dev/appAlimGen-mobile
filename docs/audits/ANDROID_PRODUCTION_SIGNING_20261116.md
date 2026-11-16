# Signature Android de production — 16 novembre 2026

La version Android `1.0.4 (20261116)` utilise désormais une identité de
production distincte de la clé de débogage. Gradle ne retombe jamais sur la clé
debug pour une build release : la configuration locale `android/key.properties`
et la clé qu'elle référence sont obligatoires.

## Identité publique vérifiée

- Sujet : `CN=El Amine ERP, OU=Mobile, O=El Amine, C=DZ`
- Algorithme : RSA 4096 bits
- Format du magasin : PKCS12
- Alias : `el-amine-erp`
- Certificat SHA-256 :
  `58a1787f37ed4c3404ff2f4f1be909f0148722ecfd1f121be2b9dc9b683bc6fe`
- Signature APK : schéma v2 valide, un seul signataire

La clé privée et ses mots de passe ne sont pas présents dans Git. Sur la machine
de génération, les deux fichiers à sauvegarder ensemble sont :

```text
%USERPROFILE%\.android\el-amine-erp-release.jks
%USERPROFILE%\.android\el-amine-erp-release.properties
```

La seconde copie doit être renommée `android/key.properties` dans un worktree de
compilation. Les deux fichiers doivent être conservés dans une sauvegarde privée,
chiffrée et testée. Perdre l'un d'eux empêcherait les futures mises à jour signées.

## Qualification de l'APK

- Application : `com.elamine.erp`
- Version : `1.0.4`, code `20261116`
- Target SDK : 36
- APK SHA-256 :
  `848EA0A3570F5B33F4DB6905973F47E957FC1CD26D08876BC4139BE87E781153`
- `flutter analyze` : réussi, aucune anomalie.
- Build release obfusquée avec symboles séparés : réussie.
- `apksigner verify --verbose --print-certs` : réussi.

Le code applicatif correspondant avait réussi 329 tests avant la fusion CY-11.
Une nouvelle exécution Windows a compilé mais son runner n'a pas rendu la main ;
elle a été interrompue sans résultat exploitable. Aucun échec de test n'a été
rapporté. La configuration Gradle est le seul changement suivi après cette
qualification applicative.

## Installation et conservation

Les APK antérieures étaient signées avec une clé debug différente. Android ne
peut donc pas installer cette première version de production comme mise à jour :
il faut désinstaller une seule fois l'ancienne application, puis installer cette
APK. Les versions futures signées avec la présente clé pourront ensuite être
mises à jour normalement.

Avant toute diffusion large, effectuer sur un appareil réel : connexion,
création/consultation de facture, affichage du stock, partage PDF, impression
Bluetooth et déconnexion/nettoyage du cache.
