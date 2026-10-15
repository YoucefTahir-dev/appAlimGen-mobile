# Lot 5 — Android et impressions carton / pièce

## Résultat

L'application Flutter utilise désormais le contrat multi-unités du backend sans dupliquer les règles de stock : les quantités saisies restent exprimées dans l'unité choisie et le serveur demeure responsable de leur conversion en unité de base.

## Couverture fonctionnelle

- Produits : choix `pièce`, `carton` ou `carton et pièce`, facteur pièces/carton et tarifs carton.
- Stock initial : saisie en pièces ou cartons avec aperçu de la quantité canonique.
- Achats : choix du conditionnement autorisé et transmission de `packaging_id`.
- Ventes : prise en charge existante conservée, avec prix du conditionnement fourni par l'API.
- Bons de chargement : choix de l'unité, transmission de `packaging_id`, lecture de la quantité saisie et de la quantité de base.
- Factures A4/58/80 mm : unité commerciale et pourcentage de TVA conservés.
- Tickets ESC/POS : ajout explicite du nom du conditionnement.
- Compatibilité : une ligne sans `packaging_id` conserve le comportement historique en unité de base.
- Langues : libellés des nouveaux champs disponibles en français, anglais et arabe, avec widgets directionnels.

## Garanties et limites

- Aucune quantité canonique n'est recalculée comme source de vérité dans Flutter ; le backend valide le facteur et les disponibilités.
- Les anciens produits et anciennes réponses API sans `unit_mode` ni conditionnement restent lisibles.
- La modification d'un produit et celle de son carton utilisent deux appels API successifs. En cas d'échec du second appel, l'erreur serveur est affichée et aucune donnée de stock n'est inventée localement.
- Aucun secret, identifiant utilisateur ou donnée de production n'est embarqué.

## Validation

- `flutter analyze` : PASS, aucune anomalie.
- Tests ciblés multi-unités, contrats API et impression : PASS (38).
- Suite Flutter complète : PASS (124).
- APK release obfusqué : PASS, `build/app/outputs/flutter-apk/app-release.apk`.
- Test sur imprimante physique RPP02N : à effectuer sur le terminal Android, le matériel Bluetooth n'étant pas accessible au poste de développement.
