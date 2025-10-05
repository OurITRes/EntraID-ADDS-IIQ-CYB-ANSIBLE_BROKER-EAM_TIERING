# CYBERARK PVWA API – Documentation Technique et Classification des Flux

## 1. Note sur la classification des flux

La classification des flux CyberArk repose sur :

- **ISO/IEC 27001:2022 A.8.2.1 – Classification of Information**
- **NIST SP 800-60 rev1 – Guide for Mapping Types of Information and Information Systems to Security Categories**

Ces normes recommandent de classifier les flux selon leur **impact sur la confidentialité, l’intégrité et la disponibilité**.
Dans le modèle **EAM (Enterprise Access Model)**, les flux CyberArk sont catégorisés comme suit :

| Niveau | Description | Exemple d’usage | Tier EAM |
|---------|--------------|----------------|-----------|
| **Critique (T0)** | Impact direct sur le contrôle de l’identité ou la compromission du domaine AD ; nécessite un poste PAW-T0 et isolation réseau complète. | Rotation de secrets ; sessions PSM ; appels API PVWA de type JIT. | T0 |
| **Sensible (T1)** | Flux de gestion et d’orchestration ; interactions automatisées sans privilèges AD directs. | Appels API via Ansible ; approbations IIQ ; synchronisations. | T1 |
| **Standard (T2)** | Flux utilisateurs non privilégiés ; aucune donnée critique manipulée. | Interfaces web, logs SIEM, lecture d’état. | T2 |

---

## 2. Présentation générale de l’API PVWA

L’API **Password Vault Web Access (PVWA)** est le point d’entrée RESTful et HMAC-signé du système **CyberArk PAM**.
Elle permet la gestion des secrets, des comptes, des sessions, et des workflows d’accès JIT/JEA.

### Caractéristiques principales

- Format : REST JSON
- Authentification : SAML/OIDC (Entra ID) + MFA ou ticket HMAC
- TLS 1.2+ obligatoire ; certificats X.509 validés
- Tous les endpoints sont journalisés dans le SIEM (T1, lecture seule)

---

## 3. Flux API typiques

### 3.1 Authentification SSO (SAML/OIDC)
- Endpoint : `/PasswordVault/API/Auth/SAML/Logon`
- Description : ouverture de session fédérée depuis Entra ID.
- Retourne un **ticket de session** (HMAC) pour les appels suivants.
- Classification : **Sensible (T1)** – flux sortant orchestré via broker (Ansible/GitHub).

### 3.2 Demande JIT (Just-In-Time)
- Endpoint : `/PasswordVault/API/Accounts/<id>/Requests`
- Payload minimal : utilisateur cible (`a-<user>`), durée, justification, labels (T0/T1).
- Appel initié depuis un **broker T1**, validé côté PVWA (T0).
- Classification : **Critique (T0)**.

### 3.3 Démarrage d’une session PSM
- Endpoint : `/PasswordVault/WebServices/PIMServices.svc/PSMConnect`
- Paramètres : plate-forme, compte cible, enregistrement vidéo = ON.
- Le PSM agit comme **proxy bastion T0**, sans contact direct avec la Vault.
- Classification : **Critique (T0)**.

### 3.4 Terminaison et rotation
- Endpoints : `/PasswordVault/API/Accounts/<id>/CheckIn`, `/PasswordVault/API/Accounts/<id>/Change`
- Objectif : fermeture de session et rotation immédiate du secret.
- Classification : **Critique (T0)**.

### 3.5 Lecture et audit des logs
- Endpoint : `/PasswordVault/API/Audit`
- Rôle : lecture seule pour export SIEM.
- Classification : **Standard (T2)** (lecture seule, aucune modification possible).

---

## 4. Tableau de classification détaillé des flux API

| Flux | Endpoint | Direction | Description | Sensibilité | Tier EAM |
|------|-----------|------------|--------------|--------------|-----------|
| Authentification SSO | `/API/Auth/SAML/Logon` | Entrant (T1 → T0) | Auth SAML/OIDC Entra ID → PVWA | Sensible | **T1** |
| Demande JIT | `/API/Accounts/<id>/Requests` | T1 → T0 | Création d’un accès JIT temporaire | Critique | **T0** |
| Session PSM | `/WebServices/PIMServices.svc/PSMConnect` | T0 ↔ Vault | Démarrage de session proxy | Critique | **T0** |
| Check-In / Rotation | `/API/Accounts/<id>/CheckIn` / `Change` | T0 ↔ Vault | Rotation du secret, clôture session | Critique | **T0** |
| Lecture audit | `/API/Audit` | T0 → T1 | Export logs → SIEM (lecture) | Standard | **T2** |

---

## 5. Exemples d’appels API

### 5.1 Authentification SAML
```http
POST /PasswordVault/API/Auth/SAML/Logon HTTP/1.1
Host: pvwa.t0.internal
Content-Type: application/json

{
  "SAMLResponse": "<assertion_base64>"
}
```

### 5.2 Demande JIT
```http
POST /PasswordVault/API/Accounts/12345/Requests HTTP/1.1
Authorization: CyberArk token=xxxxxxxxxx
Content-Type: application/json

{
  "Reason": "Admin T0 access request",
  "Duration": 60,
  "Labels": ["T0","Critical"]
}
```

### 5.3 Rotation immédiate
```http
POST /PasswordVault/API/Accounts/12345/CheckIn
POST /PasswordVault/API/Accounts/12345/Change
```

---

## 6. Sécurité et recommandations d’usage

- Tous les appels API PVWA doivent être effectués via **TLS 1.2+** avec certificats valides.
- Aucune clé HMAC ne doit être stockée en clair dans les scripts ; utiliser des **variables d’environnement**.
- Implémenter des workflows JIT avec **approbation IIQ** pour tout compte T0.
- Consommer l’API uniquement depuis les **zones T1/T0** selon la sensibilité :
  - Brokers (Ansible/GitHub) → PVWA (T0)
  - PVWA → Vault (hors EAM)
- Enregistrer tous les appels API dans le **SIEM (lecture seule)**.
- Tester régulièrement la signature HMAC et la validité du certificat PVWA.

---

## 7. Références

| Réf. | Norme / Cadre | Domaine |
|------|----------------|---------|
| [1] | **NIST SP 800-53 rev5 – PR.AC-6** | Least Privilege |
| [2] | **NIST SP 800-60 rev1** | Guide mapping TI to Security Categories |
| [3] | **ISO/IEC 27001:2022 – A.9.4.3** | Use of privileged utilities |
| [4] | **ISO/IEC 27001:2022 – A.8.2.1** | Classification de l’information |
| [5] | **CIS Controls v8 – Control 5** | Account Management |
| [6] | **Microsoft EAM** | Tiering & Access Segmentation |
| [7] | **CyberArk API Guide (v13.x)** | REST API Reference |
| [8] | **CyberArk PAM Architecture Hardening Guide v13.x** | PAM Hardening Reference |
