# Stock sur les lignes de facture Android — 14 novembre 2026

## Périmètre

Affichage ajouté au formulaire mobile de vente/facture, dès la sélection d'un
produit. Aucun changement du Web Django, de l'API, des droits ou des règles de
validation/enregistrement des ventes. Aucun déploiement ni accès aux données
de production pour la qualification. Aucun commit, push ou APK publié.

Le stock provient exclusivement du champ `stock` de la recherche commerciale
existante : le serveur l'adapte à la source de stock du vendeur. Le champ
homonyme de la réponse de prix représente le dépôt et n'est jamais utilisé
pour remplacer cette quantité. Aucun nouvel appel réseau n'est ajouté.

## Présentation

- Sous chaque produit sélectionné : « Stock disponible : N unités de base ».
- Si un conditionnement est sélectionné, ajout du nombre entier de
  conditionnements et du reliquat en unités de base. Exemple : 20 unités,
  facteur 6 → 3 conditionnements et 2 unités restantes.
- Zéro connu affiché en couleur d'avertissement ; absence ou valeur invalide
  affichée « Stock non renseigné », sans inventer un zéro.
- Traductions français, arabe et anglais, alignement directionnel, texte
  repliable sur petit écran, annonce accessible et infobulle.
- L'infobulle précise : stock à la sélection, non réservé, vérifié à
  l'enregistrement. Il ne s'agit pas d'une synchronisation temps réel ni d'un
  décompte/réservation du brouillon. La validation serveur est conservée.
- Une ligne d'une facture existante sans métadonnée de stock reste inconnue
  jusqu'à une nouvelle sélection ; aucune quantité historique vendue n'est
  confondue avec le stock actuel.

La sélection déclenche immédiatement l'affichage et efface l'ancien
conditionnement. Une réponse de prix obsolète après sélection d'un autre
produit, suppression de la ligne, fermeture ou changement de session n'est
pas appliquée par le callback de sélection de produit.

## Qualification

- 21 nouveaux tests ciblés réussis (widget et intégration formulaire, fakes).
- Dossier de travail : `flutter analyze --no-pub` sans problème ; suite
  complète **272 tests réussis**, incluant les autres travaux préexistants.
- Qualification indépendante dans une archive propre de
  `eebb8c2abaed8d92b6f7a7d4191055c0a3190450`, avec uniquement les quatre
  fichiers de code/test de ce lot superposés : analyse sans problème,
  **230 tests réussis**, aucun échec. Les deux suites ne sont pas additionnées.
- Snapshot : `tmp/mobile-stock-87c62c39b88d4b8f8d0acae6fef88b8a` du workspace
  parent ; dépendances résolues en mode offline, verrou inchangé après
  normalisation des fins de ligne. Les quatre sources/test superposés sont
  identiques par SHA-256 aux fichiers qualifiés du dossier mobile.
- Empreintes des onze fichiers suivis déjà modifiés au démarrage : inchangées.
- `git diff --check` réussi. Les autres travaux locaux et la PR mobile
  antérieure ne sont ni fusionnés ni publiés par cette modification.

Les tests couvrent notamment les stocks inconnus/nuls, conversion et reliquat,
traductions, petit écran/police agrandie, disponibilité avant retour du prix,
stock vendeur différent du dépôt, changement de conditionnement, anciennes
réponses et fermeture du formulaire. Pas de recette sur appareil Android réel
ni d'installation d'APK revendiquée. L'étape de livraison d'un nouvel APK reste
distincte de cette implémentation locale.

## APK généré à la demande explicite du propriétaire

Après la qualification, le propriétaire demande une nouvelle version. Un APK
universel a été généré depuis le dossier mobile courant, **incluant les
correctifs locaux d'impression préexistants**, qui restent conservés et hors
d'un nouveau commit. Ce n'est pas un APK constitué des seuls quatre fichiers
du lot isolé : la suite du dossier complet (272 tests) couvre ce périmètre Dart.

Commande finale réussie :

```powershell
flutter pub get --offline
flutter build apk --release --build-name=1.0.2 --build-number=20261114 --dart-define=API_BASE_URL=https://gestio-stock-web.onrender.com/api/v1/
```

La première tentative avec `--no-pub` échouait sur un registrant Java généré
contenant encore le plugin `integration_test`, alors que Gradle excluait cette
dépendance de développement en release. Le SDK Flutter local montre que
`--no-pub` court-circuite aussi la régénération des fichiers de plateforme.
La commande finale sans cette option a régénéré normalement le registrant en
mode release : plus de plugin de test. Aucun patch manuel du Java généré, du
SDK, de Gradle ou du code métier, et aucune version de dépendance changée.

### Métadonnées et contrôles du binaire

- Fichier : `build/app/outputs/flutter-apk/el-amine-stock-test-1.0.2-20261114.apk`.
- Copie de la sortie standard `app-release.apk`, empreintes identiques.
- Package : `com.elamine.erp`, libellé `EL AMINE`.
- Version **1.0.2**, code **20261114**, supérieur à l'APK local 1.0.1/20261101.
- Android minimum API 24, cible/compilation API 36.
- Architectures : arm64-v8a, armeabi-v7a, x86_64.
- Taille : **63 169 502 octets**.
- SHA-256 : `D627BCF2AE63481EAD71887B04A0881DAE602B6BF2A9A82F492BE6BE36083905`.
- `aapt2 dump badging`, `apksigner verify --print-certs` et
  `zipalign -c -P 16 4` : réussis.
- Certificat public : Android Debug ; empreinte SHA-256
  `5d2666f05a0b5c47a85dc17a24f970e9f0054fa84b10f6d3581d7a589a60f6c9`.
  Identique à l'ancien APK local nommé 1.0.1. La compilation utilise la clé
  existante : aucune nouvelle clé créée, aucun contenu de keystore ou mot de
  passe consulté manuellement ou divulgué. Configuration de signature inchangée.
- Contrôles terminés le 14 novembre à **19:16:21 Europe/Paris**.

Il s'agit d'un **APK de test signé avec la clé debug existante**, pas d'une
nouvelle signature de distribution officielle ou d'une publication Play Store.
L'identité de signature a été comparée au précédent fichier local, pas à un
téléphone connecté. Aucune installation, désinstallation ou ouverture de
l'application sur appareil n'a été effectuée. Si Android refuse la mise à jour,
ne pas désinstaller à l'aveugle : les préférences et données locales doivent
être préservées. L'ancien APK nommé 1.0.1 est conservé.

Aucun commit/push, téléchargement vers un service tiers ou déploiement serveur.
Le fichier est remis localement au propriétaire, qui décide de son installation.
