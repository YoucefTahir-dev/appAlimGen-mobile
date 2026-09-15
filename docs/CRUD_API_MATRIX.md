# Matrice CRUD mobile vérifiée

Source auditée : `ANDROID_API_GUIDE.md`, `openapi.yaml`, `apps/api/views.py` et `apps/api/serializers.py` du backend Django au 14 septembre 2026.

| Module | Lire | Créer | Modifier | Supprimer | Actions métier | Permissions Django | Endpoints |
|---|---|---|---|---|---|---|---|
| Produits | Oui | Oui | Oui, PATCH | Oui si aucune relation protégée | prix par client, recherche, code-barres, QR | `inventory.view_product`, `add_product`, `change_product`, `delete_product`; coûts: `view_product_pricing` | `products/`, `products/{id}/`, `products/{id}/price/`, `products/search/` |
| Clients | Oui | Oui | Oui, PATCH | Oui si le backend l'accepte | historique | `inventory.view_client`, `add_client`, `change_client`, `delete_client` | `clients/`, `clients/{id}/`, `clients/{id}/history/` |
| Fournisseurs | Oui | Oui | Oui, PATCH | Oui si le backend l'accepte | historique | `inventory.view_supplier`, `add_supplier`, `change_supplier`, `delete_supplier` | `suppliers/`, `suppliers/{id}/`, `suppliers/{id}/history/` |
| Charges | Oui | Oui | Oui, PATCH | Oui si le backend l'accepte | catégories séparées | `expenses.view_expense`, `add_expense`, `change_expense`, `delete_expense` | `expenses/`, `expenses/{id}/`, `expense-categories/` |
| Imprimantes | Oui | Oui | Oui, PATCH | Oui si le backend l'accepte | définir par défaut, générer payload test | `printing.view_printerprofile`, `add_printerprofile`, `change_printerprofile`, `delete_printerprofile`, `test_printerprofile` | `printers/`, `printers/{id}/`, `printers/{id}/set-default/`, `printers/{id}/test-payload/` |
| Ventes | Oui | Oui | Non | DELETE disponible, soumis aux règles serveur | création transactionnelle idempotente | `commerce.view_sale`, `add_sale`, `delete_sale` | `sales/`, `sales/{id}/` |
| Achats | Oui | Oui | Non | DELETE disponible, soumis aux règles serveur | création transactionnelle idempotente | `commerce.view_purchase`, `add_purchase`, `delete_purchase` | `purchases/`, `purchases/{id}/` |
| Paiements | Oui | Oui | Non | Non | création idempotente | permissions commerce réelles du ViewSet | `payments/`, `payments/{id}/` |
| Factures | Oui | Non | Non | Non | PDF, ticket, données d'impression | `accounts.view_invoices`, permissions d'impression | `invoices/`, `invoices/{id}/pdf/`, `ticket/`, `print-data/` |
| Stock | Oui | Non | Non | Non | mouvements/alertes en lecture; mutations via services métier | `accounts.view_stock` | `stock/`, `stock/movements/`, `stock/alerts/` |
| Bons de chargement | Oui | Oui | Brouillon seulement | Brouillon seulement selon serveur | `validate`, `close`, `cancel` | permissions `inventory.*loadingorder` | `loading-orders/` et actions dédiées |

## Décisions de sécurité

- Les boutons sont pilotés uniquement par les permissions de `GET auth/me/`; aucune détection de rôle n'est dispersée dans les écrans.
- Le serveur revalide toujours permissions, données, prix, stock et suppressions protégées.
- Les formulaires utilisent `PATCH` pour les modifications et n'écrivent jamais directement dans un journal de stock.
- Les mutations sont en ligne uniquement. Aucun stockage local silencieux n'est réalisé.
- Le test imprimante mobile vérifie le payload serveur ; le transport Bluetooth physique reste local à Android.
