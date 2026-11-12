# P1 — Intentions financières et changements de session mobiles

Date : 12 novembre 2026. Qualification locale réussie sur le périmètre ci-dessous ; aucune publication Android ni clôture globale de l’audit.

## Périmètre figé et provenance

- Dépôt mobile distinct du backend ; base Git `3f17cae5dacb834e1347fdf1249f9841a1bd86c0`.
- Archive propre de cette base, complétée par exactement **9 sources et 6 nouveaux modules de tests**. Les modifications utilisateur hors lot ne font pas partie de cette qualification.
- Snapshot local : `tmp/mobile-audit-qualified-20261112-96dfaa538e174ab5b6b88d9051cbead2/snapshot`, sous le dépôt backend parent.
- Manifeste : `source-manifest.json` dans ce même dossier de preuve, SHA-256 `6e77f2a3f2570aa2c8544b195ad888e616081b0f722babf92c1d9a2df244cefd`.
- Rapport : `qualification-result.json`, accompagné des journaux bruts. Ces preuves temporaires ne sont pas des fichiers à publier dans l’application.

Les 15 empreintes de fichiers sélectionnés correspondent au snapshot et aux sources après les tests. Un contrôle distinct confirme les 19 fichiers utilisateur hors lot inchangés **depuis le checkpoint de cette reprise** ; aucune empreinte historique du début de l’audit n’est prétendue. Le présent document est ajouté après la qualification et ne modifie aucune source testée.

## Contrats traités

Les reprises d’une intention en cours conservent leur clé d’idempotence. Pour un règlement de créance, la date est également figée au premier envoi valide. Un double clic ne lance pas un second règlement simultané. Une réponse incertaine ne provoque pas la génération silencieuse d’une autre clé dans les contrôleurs concernés.

Les formulaires financiers et les actions validation/clôture/annulation de chargement capturent la session et son jeton d’annulation dès l’intention. Ils contrôlent cette session avant l’envoi et après les réponses ; une confirmation ouverte sous A ne doit pas déclencher une action sous B. Les réponses tardives de A ne produisent pas de succès, navigation ou notification d’erreur dans B sur les écrans couverts. Un rafraîchissement transparent de jeton pour la même session reste autorisé.

Les deux périmètres suivants sont distincts :

| Contrat | Actions couvertes |
| --- | --- |
| En-tête `Idempotency-Policy: required-v1` sur les appels déjà munis d’une clé | Création/modification de vente ; création/modification d’achat ; création de paiement ; affectation d’un règlement de créance ; création/validation/clôture de chargement |
| Jeton d’annulation explicitement rattaché à la session dans les appels concernés | Création/modification de vente ; création/modification d’achat ; création de paiement ; affectation d’un règlement de créance ; validation/clôture/**annulation** de chargement |

L’en-tête n’est pas ajouté globalement à Dio ni aux actions dépourvues de clé. La création de chargement appartient au premier périmètre, pas au second ; son annulation appartient au second, pas au premier. Il n’est pas affirmé que les tests de changement de session couvrent toute l’application.

Le profil client en modification affiche le solde en lecture seule et n’envoie plus ce champ dans le PATCH. La saisie d’une dette initiale reste possible à la création. La correction financière dédiée et sa permission relèvent du backend, pas d’un nouveau bouton mobile dans ce lot.

Le dialogue de règlement utilise les libellés FR/AR/EN existants de `SalesStrings` pour le montant et le mode de paiement : le défaut de clés manquantes du dictionnaire utilisé précédemment a été reproduit puis corrigé. Ce changement ne constitue pas une refonte des traductions.

## Qualification finale

Les dépendances ont été résolues hors ligne avec verrou imposé (`--offline --enforce-lockfile`), sans changement de `pubspec.lock`. Analyse : **PASS, “No issues found”**, 6,5 secondes. Suite Flutter complète du snapshot : **201/201 tests réussis dans 40 modules**, aucun skip ni événement d’erreur, 70,584 secondes.

Les six nouveaux modules comprennent 62 tests, déjà inclus dans les 201 :

| Module | Tests réussis |
| --- | ---: |
| Annulation/session des intentions | 20 |
| Politique d’idempotence des appels financiers | 1 |
| Formulaires vente/achat/paiement et navigation tardive | 14 |
| Écriture du solde client | 3 |
| Intentions et confirmations de chargement | 18 |
| Intentions de règlement de créance | 6 |

Les scénarios réseau utilisent un transport synthétique. Ils retiennent notamment l’envoi avant le premier intercepteur asynchrone et pendant la lecture des jetons, puis changent de session : l’ancienne intention ne doit pas atteindre le transport avec la nouvelle session. Des contrôles positifs vérifient le fonctionnement normal et le rafraîchissement transparent. Les tests d’interface couvrent aussi les confirmations et réponses tardives de chargement ainsi que le dialogue de succès d’une vente avant paiement/impression.

Empreintes des journaux finaux :

- `full-tests.jsonl` : `c347ffec76e3e51d8bfe6d276b4016bb6763dd3291aee01a61cf24f4c4c26dbe`.
- `analyze.log` : `74974b026ebcf8f5c219d413653d5c5cffe346c83dc8be3acae58b9de0352f18`.
- `pub-get.log` : `44b52814abe90ef76c8744a9e7986476b84741bd7dbaef0d5ebd579ffe5faa1d`.

Une revue statique indépendante des 15 fichiers n’a relevé aucun défaut bloquant dans ce périmètre. Les essais intermédiaires en échec sont conservés séparément ; ce verdict concerne uniquement le snapshot final nommé ci-dessus.

## Sources et tests sélectionnés

```text
lib/features/business_lists/data/business_repositories.dart
lib/features/business_lists/presentation/transaction_form_screens.dart
lib/features/clients/data/clients_repository.dart
lib/features/clients/domain/client_summary.dart
lib/features/clients/presentation/client_form_screen.dart
lib/features/loading_orders/data/loading_orders_repository.dart
lib/features/loading_orders/presentation/loading_orders_screen.dart
lib/features/receivables/data/receivables_repository.dart
lib/features/receivables/presentation/receivables_screen.dart
test/core/intent_session_cancellation_test.dart
test/features/business_lists/financial_idempotency_policy_test.dart
test/features/business_lists/transaction_form_session_test.dart
test/features/clients/client_balance_write_test.dart
test/features/loading_orders/loading_order_intent_test.dart
test/features/receivables/receivable_payment_intent_test.dart
```

## Limites et publication

- Les clés restent liées à la durée de vie des contrôleurs/écrans concernés : pas de file durable ni de reprise garantie après arrêt du processus, réinstallation ou fermeture de l’intention. La durée de rétention du registre backend n’est pas changée ici.
- Pas de correction universelle des courses de session des créations de brouillon, du profil client ou des autres modules. Le framework d’authentification et les providers utilisateur ne sont pas réécrits.
- Deux messages de garde restent en français ; aucune certification complète d’internationalisation n’est revendiquée.
- Aucune compilation APK/AAB, signature, distribution, recette sur téléphone ou imprimante réelle n’est effectuée. Aucun secret ni service de production n’est utilisé par cette qualification.
- La bascule globale des clés obligatoires du backend reste désactivée par défaut pour préserver les anciens clients. Les clients existants ne sont pas déclarés tous remplacés ou qualifiés.
- Le backend est qualifié séparément dans le commit local `2282d693b4fdfecdca454b998758419a01900413`. Le raccordement opérationnel du garde-fou de migrations, la connexion directe, la formule Render et le plancher de retour de code restent à valider avant publication. La neutralité temporelle de la réinitialisation avec SMTP synchrone reste une réserve ouverte.

Verdict : candidat à un commit local limité aux fichiers sélectionnés et à ce rapport. Aucun push, fusion, déploiement, activation d’option ou publication de binaire n’est constaté ou autorisé par ce document.
