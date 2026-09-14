# EL AMINE Android

Client Flutter Android officiel de l’API Django EL AMINE. Cette application ne se connecte jamais directement à PostgreSQL, Render, Neon ou GCP : tous les échanges passent par l’API HTTPS versionnée `/api/v1/`.

## Prérequis

- Flutter 3.44.4 ou compatible, Dart 3.12+
- Android SDK, Java 17
- un compte EL AMINE de test (ne jamais versionner ses identifiants)

## Lancer l’application

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=https://gestio-stock-web.onrender.com/api/v1/
```

L’URL se termine idéalement par `/`. Elle est normalisée automatiquement. Hors `localhost`, `127.0.0.1` et émulateur `10.0.2.2`, seule une URL HTTPS est acceptée. Aucun secret n’est fourni par `dart-define`.

## Qualité et APK

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=https://gestio-stock-web.onrender.com/api/v1/
```

L’APK debug est généré dans `build/app/outputs/flutter-apk/app-debug.apk`.

## Fonctionnalités de la Phase 1

- splash natif et Flutter avec le logo officiel ;
- connexion, restauration de session, `/auth/me/`, refresh JWT et déconnexion ;
- stockage des jetons dans Android Keystore via `flutter_secure_storage` ;
- refresh single-flight : plusieurs réponses 401 simultanées produisent une seule rotation et une seule répétition par requête ;
- purge immédiate sur `TOKEN_REVOKED` ;
- navigation protégée et menu piloté par les permissions de `/auth/me/` ;
- tableau de bord simple alimenté par `/dashboard/?period=today` ;
- français, arabe RTL et anglais ;
- états explicites chargement, succès, vide et erreur ;
- préparation des clés d’idempotence UUID pour les futures écritures.

Cette phase ne demande volontairement que la permission Android `INTERNET`. Bluetooth, caméra, localisation, ventes et mode hors-ligne seront traités dans des phases ultérieures.

## Sécurité

- Ne jamais enregistrer les access/refresh tokens dans les logs.
- Ne jamais désactiver TLS ni accepter tous les certificats.
- Ne jamais placer une clé privée ou un mot de passe dans le dépôt.
- La déconnexion distante est une tentative de courtoisie ; les jetons locaux sont effacés même si le réseau est indisponible.
- Aucune mutation métier n’est mise en file hors-ligne en Phase 1.

## Tests d’intégration

Le squelette `integration_test/app_test.dart` n’embarque aucun mot de passe de production et est ignoré par défaut. Il servira à un scénario instrumenté avec un compte de staging injecté de manière sûre.

## Git

Ce dossier possède son propre dépôt Git et n’appartient pas au dépôt backend. Branche de développement initiale : `feature/flutter-foundation`.
