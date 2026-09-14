# Matrice Web / API / Flutter

Cette matrice documente la source de vérité utilisée pour le menu mobile. Les
entrées sont affichées à partir des permissions exactes renvoyées par
`GET /api/v1/auth/me/`; aucun nom de rôle n'est codé en dur.

| Rubrique Web | Permission backend | API mobile | Écran Flutter |
|---|---|---|---|
| Tableau de bord | `accounts.view_dashboard` | `/dashboard/summary/` | Oui |
| Produits | `inventory.view_product` | `/products/` | Oui, recherche et pagination |
| Clients | `inventory.view_client` | `/clients/` | Oui, recherche et pagination |
| Fournisseurs | `inventory.view_supplier` | `/suppliers/` | Oui, recherche et pagination |
| Ventes | `commerce.view_sale` | `/sales/` | Oui, pagination |
| Achats | `commerce.view_purchase` | `/purchases/` | Oui, pagination |
| Factures | `accounts.view_invoices` | `/invoices/` | Oui, pagination |
| Paiements | vente ou achat visible | `/payments/` | Oui, pagination |
| Stock global | `accounts.view_stock` | `/stock/` | Oui, recherche et pagination |
| Stock opérateur | chargements propres / vente opérateur | `/operator-stock/` | Oui, recherche et pagination |
| Bons de chargement | `inventory.view_loadingorder` ou `inventory.view_all_loadingorders` | `/loading-orders/` | Oui, recherche et pagination |
| Charges | `expenses.view_expense` | `/expenses/` | Oui, pagination |
| Imprimantes | `printing.view_printerprofile` | `/printers/` | Oui, imprimante par défaut |
| Profil | utilisateur authentifié | `/auth/me/` | Oui |
| Paramètres société | `core.view_companysettings` | **API absente** | Non affiché |

## Écarts de contrat API constatés

- L'API des paramètres société n'existe pas encore : le mobile ne présente pas
  une fausse rubrique non fonctionnelle.
- Les factures et ventes exposent l'identifiant du client, mais pas son nom. Le
  mobile affiche donc l'identifiant reçu, sans inventer de donnée.
- Le stock opérateur conserve `quantity` de `/operator-stock/` comme quantité
  restante de référence. Les quantités chargées et vendues viennent du bon de
  chargement courant et sont seulement présentées comme informations annexes.
