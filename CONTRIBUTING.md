# CONTRIBUTING

Merci de contribuer à ce dépôt. Voici les principes de base :

## 1. Branches & PR
- Forkez le dépôt & créez une branche depuis `main` (`feature/<topic>`).
- Ouvrez une Pull Request signée (GPG ou Verified).
- Respectez le modèle de commit conventionnel (`feat:`, `fix:`, `docs:`, `ci:`, etc.).

## 2. Qualité & CI
- Lint Markdown et YAML (`markdownlint`, `yamllint`).
- Liens vérifiés automatiquement (voir `.github/workflows/docs-ci.yml`).
- Les diagrammes PlantUML doivent être commités en `.puml`; les PNG sont générés par la CI.

## 3. Sécurité
- Ne committez **aucun secret** (mots de passe, tokens, clés privées).
- Utilisez des variables d’environnement et des exemples anonymisés.
- Toute vulnérabilité : voir `SECURITY.md` pour la divulgation.

## 4. Documentation
- Toute nouvelle fonctionnalité doit inclure une MAJ des docs sous `./docs/`.
- Préférez les liens relatifs `./docs/...` depuis le `README.md`.

## 5. Gouvernance
- Respect du modèle EAM (T0/T1/T2).
- Aucun code T1/T2 ne doit contacter directement des composants T0.
