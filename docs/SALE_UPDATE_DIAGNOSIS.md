# Diagnostic de la modification d’une vente

## Route et contrat vérifiés

La modification utilise `PATCH /api/v1/sales/{id}/`. Le routeur DRF expose
bien `partial_update` sur cette route et délègue les changements de vente,
de stock, de facture et de paiement au service métier transactionnel existant.

Le test d’intégration Django envoie le payload Flutter exact et reçoit `200`.
Il n’est donc pas nécessaire de modifier le backend de production.

| Champ | Web | Flutter | API attendue | État |
| --- | --- | --- | --- | --- |
| client | entier `client` | entier `client` | clé primaire entière | OK |
| produit | `product`/`product_id` normalisé | entier `product_id` | l’un des deux alias | OK |
| quantité | entier | entier `quantity` | entier positif | OK |
| conditionnement | `packaging_id` optionnel | `packaging_id` optionnel | clé primaire optionnelle | OK |
| prix unitaire | décimal | chaîne décimale `unit_price` | Decimal | OK |
| remise | décimal | chaîne décimale `discount` | Decimal | OK |
| TVA | pourcentage `19.00` | chaîne `19.00` | pourcentage Decimal | OK |
| paiement | code métier | `payment_type` | code métier | OK |
| paiement intégral | booléen | booléen `pay_full` | booléen | OK |
| lignes | liste | liste `items` | liste non vide | OK |
| total calculé | non envoyé | non envoyé | lecture seule, calcul serveur | OK |
| numéro/date/statut affiché | non envoyé | non envoyé | lecture seule | OK |

## Cause du message trompeur

L’ancien client regroupait tous les statuts HTTP `>= 500` sous le message
« Le serveur est momentanément indisponible ». Il ne journalisait pas non plus
le payload sortant ni le corps de l’erreur. Une erreur interne `500` devenait
donc indistinguable d’un `502`, `503` ou `504`.

Le mapping distingue désormais les erreurs internes des indisponibilités, et
la trace de debug indique URL sans query string, méthode, Content-Type,
présence de la clé d’idempotence, payload expurgé, statut, réponse expurgée et
durée. Les mots de passe, JWT, access tokens, refresh tokens, clés et secrets
sont masqués.

Le statut historique exact de l’essai effectué avant ce correctif n’a pas été
conservé par l’ancienne APK. Il ne doit donc pas être inventé. La prochaine
reproduction avec la nouvelle APK fournira cette valeur sans exposer de secret.
