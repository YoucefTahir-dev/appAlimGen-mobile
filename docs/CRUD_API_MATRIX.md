# Audit CRUD Flutter / API

Audit basé sur les ViewSets, serializers et permissions Django, puis sur le parcours Flutter complet (écran, provider, repository, API et rafraîchissement).

| Module | Lire | Créer | Modifier | Supprimer | Actions métier | Flutter après travaux | API disponible |
|---|---:|---:|---:|---:|---|---|---|
| Produits | Oui | Oui | Oui | Oui si accepté | prix client, recherche, code-barres, QR | CRUD avec permissions et refresh | CRUD complet |
| Clients | Oui | Oui | Oui | Oui si accepté | GPS conservé | CRUD avec permissions et refresh | CRUD complet |
| Fournisseurs | Oui | Oui | Oui | Oui si accepté | — | CRUD avec permissions et refresh | CRUD complet |
| Ventes | Oui | Oui | Non | Oui, règle serveur | prix serveur, stock opérateur, idempotence | création multi-lignes + suppression autorisée | create/list/retrieve/destroy |
| Achats | Oui | Oui | Non | Oui, règle serveur | idempotence, création produit imbriquée | création multi-lignes + suppression autorisée | create/list/retrieve/destroy |
| Factures | Oui | Non | Non | Non | PDF, ticket, données d'impression | liste, détail, PDF, impression Bluetooth | lecture + actions dédiées |
| Paiements | Oui | Oui | Non | Non | idempotence | création selon permissions commerce | create/list/retrieve |
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
- L'API ne fournit actuellement aucun endpoint de recherche des utilisateurs/opérateurs. Le formulaire de bon utilise donc l'identifiant opérateur ; une sélection par nom nécessite d'abord un endpoint backend autorisé.

## Architecture d'impression

`Django (configuration/données) -> Flutter Android -> Bluetooth Classic RFCOMM -> RPP02N`

Le serveur Render n'ouvre jamais le Bluetooth. Le code sépare `PrinterTransport`, `BluetoothPrinterTransport`, `PrinterDriver` et `EscPosPrinterDriver`. Un statut « données envoyées » ne vaut pas confirmation de sortie papier.

## Recette physique RPP02N obligatoire

1. Allumer la RPP02N et charger du papier 80 mm.
2. Activer le Bluetooth Android et appairer `RPP02N` dans les réglages du téléphone.
3. Dans Imprimantes, vérifier le nom/adresse Bluetooth, activer le profil et le définir par défaut.
4. Appuyer sur « Tester l'impression » et accepter `BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN` si Android les demande.
5. Vérifier connexion, texte ASCII, alignements et largeur du ticket papier.
6. Ouvrir une facture puis appuyer sur « Imprimer » ; un échec d'impression ne doit jamais annuler la vente.
7. L'arabe rasterisé et le QR nécessitent une phase suivante et une validation matérielle : le driver actuel évite volontairement d'envoyer de l'arabe natif cassé.

## Réserves connues

- Sélection conviviale d'opérateur : endpoint backend absent.
- Arabe rasterisé et QR ESC/POS : non déclarés prêts avant essai matériel et ajout du driver image.
- La validation physique RPP02N ne peut être conclue par les tests automatiques.
