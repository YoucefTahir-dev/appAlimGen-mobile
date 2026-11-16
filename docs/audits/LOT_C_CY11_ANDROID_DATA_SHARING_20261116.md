# Lot C — CY-11 : sauvegardes Android et partage de PDF

Date : 16 novembre 2026. Correctif qualifié dans un clone isolé du dépôt
mobile, sans accès à la production ni installation sur un appareil réel.

## Périmètre corrigé

- Les sauvegardes Android sont explicitement désactivées avec
  `android:allowBackup="false"`.
- Des règles complètes excluent les domaines privés des sauvegardes historiques
  et modernes, y compris le transfert direct vers un nouvel appareil. Elles
  restent présentes comme défense en profondeur face aux variations de
  comportement des versions et constructeurs Android.
- Le `FileProvider` non exporté ne partage plus la racine du cache : seul le
  sous-répertoire `invoice-pdfs/` est déclaré.
- Le code natif refuse tout chemin non canonique, tout fichier hors de ce
  répertoire et tout nom qui ne respecte pas
  `facture_<identifiant>_<horodatage>.pdf`.
- Le partage accorde uniquement un droit de lecture temporaire à l'application
  destinataire. Aucun droit d'écriture ni URI `file://` n'est utilisé.
- Un seul PDF temporaire géré est conservé à la fois. Les PDF gérés sont purgés
  au démarrage, avant une nouvelle écriture et lors de la déconnexion. La
  déconnexion attend la purge ; un échec de cache ne bloque jamais
  l'authentification. Les autres fichiers du cache ne sont pas supprimés.
- Les jetons restent dans `FlutterSecureStorage`. Ce lot ne modifie ni les
  contrats API, ni les ventes, ni les factures, ni les permissions métier.

Références primaires :
[sauvegardes Android](https://developer.android.com/identity/data/autobackup),
[FileProvider](https://developer.android.com/reference/androidx/core/content/FileProvider)
et [risques de partage de fichiers](https://developer.android.com/privacy-and-security/risks/file-providers).

## Qualification locale

- `dart format` : 8 fichiers ciblés, aucune modification résiduelle.
- `flutter analyze` : aucune anomalie.
- Tests ciblés CY-11 : 21/21 réussis.
- Suite Flutter complète, séquentielle : 329/329 réussis.
- APK release obfusqué construit : version `1.0.4+20261116`, 56,1 Mo.
- Manifeste fusionné vérifié : sauvegarde désactivée, deux fichiers de règles
  présents, `FileProvider` non exporté et permission d'URI activée.
- Ressources compilées inspectées avec `aapt2` : le fournisseur expose seulement
  `invoice-pdfs/`; les neuf domaines sont exclus des règles historiques, du
  cloud et du transfert d'appareil.
- APK : SHA-256
  `DBD929E779D7D1ECE34DB124398F2991B84C2963D844D4B30576A69674A11801`.

## Limite bloquante pour la distribution

Le type `release` utilise encore explicitement la clé Android de debug. La
signature V2 est techniquement valide, mais le certificat est
`CN=Android Debug` (empreinte SHA-256
`5d2666f05a0b5c47a85dc17a24f970e9f0054fa84b10f6d3581d7a589a60f6c9`).
La compatibilité avec la signature de l'APK réellement installé n'est pas
prouvée. L'APK construit est donc un artefact de contrôle et ne doit pas être
distribué.

Avant toute diffusion, il faut disposer de la clé de publication légitime,
comparer son certificat avec la version installée, reconstruire, puis tester
sur appareil réel : mise à niveau sans perte de session, ouverture/partage du
PDF avec une visionneuse, révocation du droit après usage, déconnexion et
reconnexion sous un second compte. Les parcours Bluetooth doivent également
être rejoués sur matériel. Aucun de ces contrôles ne peut être honnêtement
remplacé par l'émulateur ou les tests locaux actuels.
