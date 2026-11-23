# Android — CY-09 et chaîne de livraison

Le formulaire de vente affiche toujours le tarif calculé par l'API. Le champ
est désormais en lecture seule si `/auth/me` n'accorde pas
`commerce.override_sale_price`, avec une explication FR/AR/EN. Les anciens
clients restent protégés par le contrôle serveur.

Version candidate : `1.0.5+20261122`.

La CI utilise Flutter 3.44.4, Java 17, des actions verrouillées par SHA, des
permissions GitHub minimales, le verrou de dépendances, l'analyse, les tests et
une compilation debug. La publication signée est séparée et ne peut produire
un APK que si les quatre secrets de production sont présents. Elle vérifie la
signature, publie l'empreinte SHA-256, la provenance du commit et les symboles
d'obfuscation, puis supprime le keystore temporaire.

Qualification locale : analyse sans anomalie, 334 tests réussis, compilation
APK debug réussie. Aucune clé privée ni aucun mot de passe n'a été lu,
copié ou ajouté au dépôt pendant cette qualification.
