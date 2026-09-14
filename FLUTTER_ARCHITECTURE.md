# Architecture Flutter — fondation Phase 1

## Principes

L’application utilise une architecture **feature-first**. Les écrans métier vivent dans `lib/features/<feature>` et les briques transverses dans `lib/core`. Riverpod est l’unique système d’état et d’injection ; `go_router` est l’unique routeur ; Dio est l’unique client HTTP.

```text
lib/
├── app/                    # composition, thème, routes, providers racine
├── core/
│   ├── config/             # API_BASE_URL et garde HTTPS
│   ├── errors/             # AppFailure + ErrorMapper central
│   ├── network/            # Dio, enveloppes, JWT, événements de session
│   ├── storage/            # abstraction et stockage sécurisé des tokens
│   ├── utils/              # générateur de clés d’idempotence UUID
│   └── widgets/            # composants partagés
├── features/
│   ├── auth/               # repositories, modèles immuables, controller, login
│   ├── dashboard/          # repository API, modèle KPI, états et écran
│   └── profile/            # profil et logout
└── l10n/                   # catalogue FR/AR/EN et delegate
```

## Flux d’authentification

1. Au splash, `AuthController.restore()` lit le stockage sécurisé.
2. Sans tokens, la route devient `/login`.
3. Avec tokens, l’application appelle `/auth/me/`; l’intercepteur peut rafraîchir automatiquement l’access token.
4. Au login, `/auth/login/` fournit access/refresh, puis `/auth/me/` fournit le profil et les permissions.
5. Un 401 ordinaire rejoint une opération de refresh partagée. La requête n’est rejouée qu’une fois.
6. `TOKEN_REVOKED` ou un refresh impossible purge le stockage, publie un événement d’expiration et renvoie vers `/login`.
7. Le logout tente `/auth/logout/` avec le refresh puis efface toujours la session locale.

Les écrans ne lisent jamais les tokens. Ils parlent aux controllers/repositories injectés par Riverpod.

## Contrat API et erreurs

`ApiEnvelope` exige `{"success": true, "data": ...}`. `ErrorMapper` convertit Dio et `success/error` en `AppFailure` typé : validation, authentification, permission, not found, rate limit, réseau, timeout, serveur ou inconnu. Les codes stables du backend, notamment `TOKEN_REVOKED`, restent l’autorité.

Le client envoie `Accept: application/json`, `Accept-Language: fr|ar|en` et `Authorization: Bearer ...` sur les routes protégées. Aucun logger HTTP n’est installé en production.

## Idempotence et futur hors-ligne

`IdempotencyKeyGenerator` produit des UUID. Les futures mutations commerciales devront créer une clé au début de l’intention, la conserver avec le corps exact et la réutiliser pour chaque retry. La Phase 1 ne réalise aucune écriture métier et n’implémente aucun faux mode hors-ligne.

## Modèles et états

Les modèles sont immuables et désérialisés explicitement. Ce choix léger évite du code généré au démarrage du projet tout en conservant un typage strict. Les features futures pourront adopter Freezed si leur complexité le justifie.

Le tableau de bord utilise `AsyncValue<DashboardSummary>` et rend quatre états distincts : chargement, succès, vide, erreur. L’authentification expose `AuthStatus` plutôt qu’une collection de booléens ambigus.

## Permissions et navigation

Les permissions reçues de `/auth/me/` déterminent la visibilité des entrées. Cette visibilité n’est qu’ergonomique : Django reste l’autorité et chaque 403 est traité comme un refus réel. Une route de nouvelle feature devra vérifier l’état de session et son écran devra respecter la permission serveur associée.

## Décisions Android

- `applicationId` : `com.elamine.erp`
- nom visible : `EL AMINE`
- `minSdk` 24 : minimum de Flutter 3.44 et base moderne pour le stockage AES-GCM/RSA du Keystore
- Phase 1 : permission `INTERNET` uniquement
- logo officiel repris depuis le backend pour le splash et le login
- aucune configuration Bluetooth, caméra ou localisation avant la phase qui les utilise

## Stratégie de tests

- stockage et sessions en mémoire ;
- Dio simulé pour login, échec, logout, réseau et révocation ;
- adaptateur HTTP déterministe pour le refresh concurrent single-flight ;
- providers/notifiers Riverpod surchargés dans les widget tests ;
- login : validation, chargement, erreur ;
- dashboard : chargement et succès KPI ;
- profil : déclenchement du logout ;
- squelette instrumenté sans secret pour une future recette staging.
