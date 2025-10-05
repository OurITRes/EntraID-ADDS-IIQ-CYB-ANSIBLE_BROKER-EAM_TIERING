# CyberArk PVWA API – exemples (placeholders)

> Ces appels sont des **exemples** à adapter à votre politique (URL, certificats, collections Postman, etc.).

## 1) Authentification SSO (SAML/OIDC)
- Utiliser l'authentification fédérée (identité T2) + MFA.
- Récupérer un **ticket**/jeton de session pour requêtes suivantes.

## 2) Demande JIT (T1 ou T0)
- Endpoint: `/PasswordVault/API/Accounts/<id>/Requests`
- Payload minimal: utilisateur cible (`a-<user>`), **durée**, justification, *labels* (T0/T1), **approbations** requises.

## 3) Démarrer une session PSM
- Endpoint: `/PasswordVault/WebServices/PIMServices.svc/PSMConnect`
- Paramètres : plate-forme, compte cible, **enregistrement vidéo** = ON.

## 4) Terminer et rotation
- À la fermeture de session: **check-in** + **rotation** des secrets.

> Conseil : utilisez une **collection Postman** commitée dans `docs/` et paramétrée via **variables d'environnement** (pas de secrets en clair).
