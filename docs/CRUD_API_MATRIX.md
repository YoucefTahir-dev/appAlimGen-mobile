# Audit CRUD Flutter / API

Audit basé sur les ViewSets, serializers et permissions Django, puis sur le parcours Flutter complet (écran, provider, repository, API et rafraîchissement).

| Module | Lire | Créer | Modifier | Supprimer | Actions métier | Flutter après travaux | API disponible |
|---|---:|---:|---:|---:|---|---|---|
| Produits | Oui | Oui | Oui | Oui si accepté | prix client, recherche, code-barres, QR | CRUD avec permissions et refresh | CRUD complet |
| Clients | Oui | Oui | Oui | Oui si accepté | GPS conservé | CRUD avec permissions et refresh | CRUD complet |
| Fournisseurs | Oui | Oui | Oui | Oui si accepté | — | CRUD avec permissions et refresh | CRUD complet |
| Ventes | Oui | Oui | Oui | Oui, règle serveur | prix serveur, stock opérateur, idempotence | liste ouvrable, détail, création/modification multi-lignes, paiements et suppression autorisée | create/list/retrieve/update/destroy |
| Achats | Oui | Oui | Non | Oui, règle serveur | idempotence, création produit imbriquée | création multi-lignes + suppression autorisée | create/list/retrieve/destroy |
| Factures | Oui | Non | Via vente | Non | PDF, ticket, données d'impression | cartes, détail, aperçus 58/80/A4, PDF et impression/réimpression Bluetooth | lecture + actions dédiées |
| Paiements | Oui | Oui | Non | Non | idempotence | création depuis la vente et historique intégré | create/list/retrieve |
| Stock global | Oui | Non | Non | Non | mouvements et alertes | lecture seule volontaire | lecture seule |
| Mon stock | Oui | Non | Non | Non | chargé/vendu/restant | lecture seule volontaire | lecture seule et cloisonnée |
| Bons de chargement | Oui | Oui | Brouillon | Brouillon via annulation | valider, annuler, clôturer | workflow et recherche produits | CRUD + actions dédiées |
| Charges | Oui | Oui | Oui | Oui si accepté | catégories | CRUD avec permissions et refresh | CRUD complet |
| Imprimantes | Oui | Oui | Oui | Oui si accepté | défaut, payload test, test physique local | CRUD, défaut et transport Bluetooth | CRUD + actions dédiées |

## Règles appliquées

- Les boutons utilisent les permissions de `GET /auth/me/`, jamais un simple test de rôle.
- Toute règle sensible reste revalidée par Django : prix, stock opérateur, état du bon et suppressions.
- Les mutations critiques gardent une même `Idempotency-Key` pendant toute la durée du formulaire et ses retries.
- Les boutons d'enregistrement sont désactivés pendant l'envoi et les listes sont rafraîchies après succès.
- Aucun `PATCH` direct du stock n'est exposé.
- La modification d'une vente remplace ses lignes dans une transaction Django : restauration des anciennes quantités, validation du stock opérateur, application des nouvelles lignes et recalcul serveur des montants.
- L'API ne fournit actuellement aucun endpoint de recherche des utilisateurs/opérateurs. Le formulaire de bon utilise donc l'identifiant opérateur ; une sélection par nom nécessite d'abord un endpoint backend autorisé.

## Matrice Ventes / Factures

| Action | Web | API | Flutter | Permission | Résultat |
|---|---:|---:|---:|---|---|
| Voir vente | liste | retrieve | détail dédié | `commerce.view_sale` | prêt |
| Modifier vente | oui | PUT/PATCH | formulaire prérempli | `commerce.change_sale` | prêt, stock transactionnel Django |
| Voir facture | aperçu | retrieve invoice | détail métier + aperçu document | `accounts.view_invoices` | prêt |
| Aperçu 58/80/A4 | 58/80 + PDF | retrieve + print-data + PDF | renderer commun, trois layouts | `accounts.view_invoices` | prêt |
| PDF facture | oui | `invoices/{id}/pdf/` | ouverture locale authentifiée | `accounts.download_invoice_pdf` | prêt |
| Imprimer / réimprimer | oui | `print-data` | Bluetooth local | `accounts.print_invoice` | logiciel prêt, test physique requis |
| Créer paiement | oui | POST payments | formulaire prérempli | `commerce.change_sale` | prêt, idempotent |
| Voir paiements | oui | inclus + filtre payments | historique dans les détails | `commerce.view_sale` | prêt |
| Annuler vente | non | non | non affiché | — | N/A |
| Supprimer vente | oui | DELETE protégé | action explicitement nommée Supprimer | `commerce.delete_sale` | prêt, jamais présentée comme annulation |

## Architecture d'impression

`Django (configuration/données) -> Flutter Android -> Bluetooth Classic RFCOMM -> RPP02N`

Le serveur Render n'ouvre jamais le Bluetooth. Le code sépare `PrinterTransport`, `BluetoothPrinterTransport`, `PrinterDriver` et `EscPosPrinterDriver`. Les largeurs sont centralisées dans `ThermalPaperSpec` (58 mm = 384 points/32 colonnes, 80 mm = 576 points/48 colonnes). Pour l'arabe, le document Flutter est converti en raster monochrome ESC/POS avant l'envoi local. Un statut « données envoyées » ne vaut pas confirmation de sortie papier.

## Recette physique RPP02N obligatoire

1. Allumer la RPP02N et charger du papier 80 mm.
2. Activer le Bluetooth Android et appairer `RPP02N` dans les réglages du téléphone.
3. Dans Imprimantes, vérifier le nom/adresse Bluetooth, activer le profil et le définir par défaut.
4. Appuyer sur « Tester l'impression » et accepter `BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN` si Android les demande.
5. Vérifier connexion, texte ASCII, alignements et largeur du ticket papier.
6. Ouvrir une facture puis appuyer sur « Imprimer » ; un échec d'impression ne doit jamais annuler la vente.
7. Tester une facture contenant un client et des produits arabes : le chemin raster doit produire un ticket lisible et aligné.

## Réserves connues

- Sélection conviviale d'opérateur : endpoint backend absent.
- Arabe rasterisé : implémenté logiciellement, validation physique obligatoire sur RPP02N.
- QR ESC/POS : non imprimé par le driver mobile actuel.
- La validation physique RPP02N ne peut être conclue par les tests automatiques.
