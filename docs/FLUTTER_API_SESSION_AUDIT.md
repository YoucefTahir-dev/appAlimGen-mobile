# Audit Flutter ↔ API Django

Référence backend auditée : commit `3028d56`, `ANDROID_API_GUIDE.md`,
`ANDROID_READINESS.md`, `ANDROID_READINESS_MATRIX.md`, serializers, vues DRF et
`openapi.yaml`.

## Matrice de communication

| Fonction | Endpoint | Méthode | Modèle Flutter | État après correction |
|---|---|---|---|---|
| Login | `/api/v1/auth/login/` | POST | `LoginResult` | Connecté au backend |
| Rotation JWT | `/api/v1/auth/refresh/` | POST | `StoredTokens` | Rotation sérialisée et sauvegarde atomique |
| Profil/permissions | `/api/v1/auth/me/` | GET | `UserProfile` | Source unique de l'utilisateur et du RBAC |
| Logout | `/api/v1/auth/logout/` | POST | enveloppe API | Best effort serveur, purge locale garantie |
| Dashboard | `/api/v1/dashboard/` | GET | `DashboardSummary` | Contrat étendu et filtre période réel |
| Produits | `/api/v1/products/` | GET | `PageData<ProductSummary>` | Pagination, `search`, annulation, refresh |
| Clients | `/api/v1/clients/` | GET | `PageData<ClientSummary>` | Pagination, `search`, refresh |
| Fournisseurs | `/api/v1/suppliers/` | GET | `PageData<SupplierSummary>` | Pagination et refresh |
| Ventes | `/api/v1/sales/` | GET | `PageData<SaleSummary>` | Pagination et données API |
| Achats | `/api/v1/purchases/` | GET | `PageData<PurchaseSummary>` | Pagination et données API |
| Factures | `/api/v1/invoices/` | GET | `PageData<InvoiceSummary>` | Pagination et données API |
| Paiements | `/api/v1/payments/` | GET | `PageData<PaymentSummary>` | Pagination, filtrage backend |
| Stock global | `/api/v1/stock/` | GET | `PageData<ProductSummary>` | Permission serveur et pagination |
| Stock opérateur | `/api/v1/operator-stock/` | GET | `PageData<OperatorStockSummary>` | Solde `quantity` exclusivement serveur |
| Bon courant | `/api/v1/loading-orders/current/` | GET | `LoadingOrderSummary?` | Chargé/vendu fournis par le serveur |
| Bons | `/api/v1/loading-orders/` | GET | `PageData<LoadingOrderSummary>` | Pagination et isolation backend |
| Charges | `/api/v1/expenses/` | GET | `PageData<ExpenseSummary>` | Pagination et données API |
| Imprimante | `/api/v1/printers/default/` | GET | `PrinterSummary?` | Configuration réelle, 404 = aucune valeur |

Toutes ces requêtes utilisent le même `ApiClient.dio`. Le second client Dio est
réservé exclusivement à la rotation JWT afin d'éviter la récursion de
l'interceptor d'authentification.

## Causes racines trouvées

1. Le modèle dashboard ne lisait que sept champs alors que l'API en expose plus
   de trente. Les charges, gains brut/net, alertes et comparaisons étaient donc
   ignorés.
2. Un dashboard contenant de vraies valeurs zéro était assimilé à un état vide.
   La réponse serveur est maintenant toujours affichée comme un succès, y
   compris lorsqu'elle contient zéro.
3. Le filtre dashboard était fixé à `today` dans le repository. Il accepte
   maintenant les périodes `today`, `yesterday`, `week`, `month`, `year` et
   `custom`, avec les dates envoyées au backend.
4. Les access/refresh tokens étaient enregistrés sous deux clés successives.
   Une interruption entre les écritures pouvait produire une paire incohérente.
   La paire complète est maintenant encodée sous une seule clé sécurisée, avec
   migration automatique des anciennes clés.
5. Les recherches Produits précédentes n'étaient pas annulées. Une réponse
   ancienne pouvait consommer du réseau inutilement. Une seule recherche de
   première page reste active et le debounce est de 300 ms.
6. Le diagnostic réseau ne permettait pas de savoir si la requête était partie.
   En debug uniquement, l'application journalise désormais méthode, chemin,
   statut et durée, sans query string, corps, mot de passe ni Authorization.
7. Le timeout d'envoi Dio manquait. Les trois délais sont maintenant bornés :
   connexion 15 s, envoi 15 s, réception 25 s.

Les écrans paginés possédaient déjà quatre états explicites
`Loading/Success/Empty/Error`. Les tests widget garantissent désormais qu'une
réponse Produits vide ou en erreur supprime bien le spinner et offre Réessayer.

## Session et sécurité

- restauration : stockage sécurisé → `/auth/me/` → refresh automatique sur 401
  → rejeu unique de la requête ;
- concurrence : un seul Future de refresh est partagé entre les requêtes 401 ;
- rotation : nouvel access et nouveau refresh sauvegardés ensemble ;
- révocation/refresh invalide : purge des tokens, événement global, état
  `unauthenticated` et retour au Login avec message d'expiration ;
- logout : l'appel serveur est tenté, puis la paire locale est toujours effacée ;
- permissions : le menu et les guards utilisent le même `UserProfile` chargé
  par `/auth/me/`, tandis que DRF reste l'autorité finale.

## Dashboard Web/API/Flutter

Le mobile affiche maintenant le chiffre d'affaires du jour et de la période,
nombre de ventes, panier moyen, gain brut, charges, gain net, valeur du stock,
total achats, produits/clients/fournisseurs, mouvements opérationnels, alertes,
comparaisons avec la période précédente, meilleurs produits et meilleurs
clients. Les zéros sont des valeurs serveur, jamais des placeholders.

Réserve backend : l'API indique `can_filter_users` mais ne fournit ni la liste
des utilisateurs disponibles ni un endpoint mobile équivalent. Le filtre
Utilisateur ne peut donc pas être implémenté correctement sans inventer des
données. Les graphiques et les classements secondaires restent une amélioration
UI ultérieure ; les séries sont déjà présentes dans `chart_data` côté API.

## Données factices

Aucun mock, fixture, délai artificiel ou compteur codé en dur n'est utilisé dans
`lib/`. Les mocks restent exclusivement dans `test/`.
