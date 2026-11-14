# Créances mobiles — livraison de revue, sans publication

14 novembre 2026, Europe/Paris. Le propriétaire autorise le commit et le push
sur une branche de revue mobile uniquement. Aucune fusion, diffusion d'APK,
installation sur appareil, modification de production ou automatisation de
sauvegarde n'est incluse.

## Contrat et comportement

Le détail appelle exclusivement
`GET /api/v1/receivables/{id}/account-page/`, avec le marqueur
`receivable-account-page-v1` et une taille de page de 25. Factures, règlements
de factures et règlements de dette antérieure ont trois navigations indépendantes.
Une navigation remplace les données affichées, sans accumulation ni récupération
automatique des autres pages : au plus 25 factures et 50 règlements par réponse.

Il n'existe aucun repli vers l'ancien détail non borné, y compris en cas de
401/403/404/405/500. Les contrats inconnus, listes absentes, métadonnées invalides
et réponses dépassant leur taille annoncée sont refusés. Une page plus courte
est admise pour tolérer une modification concurrente entre compte et lecture SQL.

Les totaux restent globaux, indépendants des lignes affichées. Le bouton de
règlement dépend du solde global positif et de la permission existante, pas de
la présence d'une facture impayée sur la page courante. La dette antérieure
commune reste encaissable conformément au choix du propriétaire. Après une
mutation réussie, les trois navigations repartent à leur première page.
Les clés d'intention, les jetons de session et les montants envoyés pour les
règlements ne changent pas. Les boutons de navigation sont traduits en français,
arabe et anglais. Aucun nouveau droit métier n'est attribué.

## Qualification de cette livraison

Base : `53c7adb2dbf969e3ffa5dbd6a0ad30f4209a2879`, qui comprend la préparation
antérieure P1 des intentions financières. La branche de revue dépend de cette
base ; elle ne prétend pas être déjà intégrée à `main`.

Qualification finale dans une copie créée par `git archive` de cette base,
puis copie des seuls neuf fichiers sources/tests du présent correctif. Les
changements locaux préexistants d'imprimantes, produits, providers et Android
sont exclus de cette copie et du commit.

- Flutter 3.44.4 / Dart 3.12.2, dépendances locales existantes, aucun changement
  de `pubspec.yaml` ou `pubspec.lock`.
- `flutter analyze --no-pub` : aucun problème.
- `flutter test --no-pub --reporter expanded` : **209 tests réussis**, sortie 0.
- Contrat réseau, trois navigations, relance après panne, absence de repli,
  bornes de mémoire côté modèles, dette commune et tests existants des
  intentions/session de règlement couverts avec des données synthétiques.
- Aucune requête métier réelle ni recette sur appareil n'est revendiquée.
- Aucun workflow CI mobile n'est configuré lors de cette livraison. Le résultat
  local n'est pas présenté comme une validation GitHub Actions.

Empreintes SHA-256 des neuf sources qualifiées :

```text
b338f33e4a16eaa50e1a30fac19996f8581f036a4edf8e43e79ede13be358bf4 lib/features/receivables/data/receivables_repository.dart
b71cb42f92b9c05bc47a07248be48f58103fdd92bb466b7ad3837b526ec5d88e lib/features/receivables/domain/receivable.dart
76635fd1a66fa280d7253d3ecadac4ec329f1c780e60b8d227d0020bd8f3bb8a lib/features/receivables/presentation/receivables_screen.dart
349e49def172e0812cda69eaddb58554812ac7f18f5d426eb7c3de15996f3034 lib/l10n/app_localizations.dart
b138d4455e77a1279e4b54db52edf7153c01bdbbae1d262e377156670287585c test/features/receivables/receivable_payment_intent_test.dart
a91540aab2a624025ea819bc4dd188b0f99c242df8b907af0195387dce060eb3 test/features/receivables/receivables_repository_test.dart
2a58602b24cae322132196b42b97263979f1a2023dd8ae22a0a86e27b7f4a8d1 test/features/receivables/receivable_page_fixture.dart
854abe7197c1228e6fb26f3665b4217ba093af7dc597ea2c0fcebfef188d97ca test/features/receivables/receivable_account_page_test.dart
7fb1677a37ecdea58b6355eb7a6be0030eb1fccc309618fed6513d01482a1c99 test/features/receivables/receivable_pagination_screen_test.dart
```

## Ordre de publication à respecter

1. Publier le backend avec l'action `account-page` et vérifier les permissions
   du vendeur sur cette API. La préparation backend est sur une branche de revue
   distincte ; le push mobile ne la publie pas.
2. Recetter cette version mobile sur un environnement autorisé, notamment la
   navigation entre pages et les règlements à partir d'un solde global.
3. Construire puis distribuer le mobile uniquement après cette validation.
4. Conserver l'ancien endpoint tant que des versions installées l'utilisent.
   Son retrait exige une décision distincte et un suivi d'adoption.

Ne pas diffuser ce mobile contre un ancien serveur : le détail y échouerait
volontairement plutôt que de charger silencieusement tout l'historique. Aucune
activation de mails différés ou opération GPS n'est liée à cette livraison.
