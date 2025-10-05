# CYBERARK – Architecture, Composants et Sécurité

## 1. Introduction

CyberArk constitue le socle de sécurité des identités à privilèges dans la solution **EntraID – ADDS – IIQ – Ansible – EAM**.
Il opère comme système de gestion et d’audit des accès privilégiés, garantissant l’application des principes **Zero Trust**, **Least Privilege** et **Just-In-Time (JIT)** pour tous les comptes à privilèges.

Les modules principaux de CyberArk (Vault, PVWA, CPM, PSM) sont intégrés dans l’architecture EAM de la manière suivante :

- **Vault** : racine de confiance, hors EAM, stockage des secrets.
- **PVWA (Password Vault Web Access)** : interface API et web pour les flux JIT, accès et audit.
- **CPM (Central Policy Manager)** : rotation et gestion des secrets.
- **PSM (Privileged Session Manager)** : proxy et enregistrement des sessions administratives.

---

## 2. Composants et Architecture

### 2.1 Digital Vault (hors EAM)
- Stocke l’ensemble des *safes* et secrets.
- Fonctionne en enclave sécurisée, non jointe au domaine AD.
- Communique uniquement via TCP 1858/1859 avec PVWA/CPM/PSM.
- Intègre un chiffrement AES-256 FIPS-compliant.

### 2.2 PVWA (API / Web)
- Interface utilisateur et API REST/HMAC.
- Hébergé sur un serveur du **Tier 0**, car en contact direct avec la Vault.
- Authentification SAML/OIDC (EntraID) + MFA.

### 2.3 CPM (Central Policy Manager)
- Rotation automatisée des comptes privilégiés (AD, systèmes, bases).
- Opère sous supervision du PVWA.
- Classé **T0** : interagit avec des comptes sensibles AD et DC.

### 2.4 PSM (Privileged Session Manager)
- Proxy sécurisé pour connexions RDP, SSH, Web.
- Enregistre les sessions (vidéo et métadonnées).
- Hébergé en **T0** avec accès restreint via PAW-T0.

### 2.5 PSM Jump et PSM Gateway
- Utilisés pour le routage des sessions via bastion.
- Sécurisés et isolés réseau.
- Aucune interaction directe avec la Vault.

### 2.6 Disaster Recovery Vault
- Réplication unidirectionnelle, chiffrée.
- Séparée logiquement et physiquement de la Vault primaire.

---

## 3. Flux Fonctionnels (vue architecture)

```
[T1 IIQ/Ansible] --> [T0 PVWA/API] --> [Vault]
                           |
                           v
                     [CPM/PSM/DC]
```

- **Flux 1 : Provisioning standard (T2)**  
  IIQ envoie une requête vers Ansible (T1), qui agit comme **broker** non-T0 et appelle l’API PVWA (T0) pour initier un compte JIT.

- **Flux 2 : Session privilégiée (T0)**  
  PVWA autorise le PSM à établir une session via un compte temporaire ou un secret géré.

- **Flux 3 : Rotation automatique**  
  CPM contacte la Vault pour récupérer et changer un secret après expiration, selon la stratégie définie.

- **Flux 4 : Audit et journalisation**  
  Les événements PSM et CPM sont envoyés vers le SIEM (lecture seule, T1).

---

## 4. Intégration avec IIQ, EntraID et Ansible

### 4.1 Intégration avec SailPoint IIQ
- IIQ agit comme orchestrateur **T1** et ne contacte jamais la Vault directement.
- Un playbook **Ansible/GitHub Actions** fait office d’intermédiaire (“broker”) :
  - Authentifie sur PVWA (API/HMAC).
  - Demande un accès JIT pour un administrateur.
  - Relaye la session PSM.

### 4.2 Intégration avec Entra ID
- L’authentification des utilisateurs administratifs se fait via **SAML/OIDC**.
- Les comptes EntraID standards (T2) ne possèdent pas d’accès permanent.
- Les administrateurs **T0/T1** activent leur session via PIM + PVWA.

### 4.3 Intégration avec Ansible
- Les rôles Ansible utilisent l’API PVWA pour effectuer :
  - Des requêtes de secrets.
  - Des rotations planifiées.
  - Des déclenchements de sessions JIT automatisées.

---

## 5. Sécurité, Tiering et Durcissement

| Composant | Tier | Sécurité appliquée | Contrôles |
|------------|------|--------------------|------------|
| **Vault** | Hors EAM | Chiffrement AES-256, isolation réseau, comptes locaux uniquement | FIPS, HSM, MFA |
| **PVWA** | T0 | Auth fédérée, HTTPS TLS1.2+, HSTS | HMAC signée, rotation clés |
| **CPM** | T0 | Rotation automatique, privilèges contrôlés | PAM Policy enforced |
| **PSM** | T0 | Session proxyée, enregistrement vidéo | Bastion, PAW-T0 |
| **Broker Ansible** | T1 | Appel API REST, sans compte T0 permanent | HMAC, variable d’environnement |
| **IIQ** | T1 | Gouvernance des rôles et provisioning | Intégration orchestrée, auditée |
| **Entra ID** | T0 | Gestion des approbations MFA et activation PIM | Journalisation, contrôle d’accès |

### 5.1 Contrôles de sécurité
- MFA obligatoire avant toute session PSM.  
- Rotation automatique à chaque fin de session.  
- Logs détaillés (`/vault/logs/psm_sessions.json`).  
- Intégration SOC via Splunk pour corrélation des anomalies.

---

## 6. Gouvernance et Bonnes Pratiques

- Utiliser des **PAW distincts** pour T0, T1, T2.
- Forcer l’authentification MFA + PIM sur PVWA.
- Jamais de credentials stockés en clair dans les playbooks ou pipelines CI/CD.
- Définir une **politique de rotation** adaptée (ex : 24h pour comptes critiques).
- Centraliser les journaux PSM/CPM dans le **SIEM (lecture seule)**.
- Mettre en place des **alertes corrélées** sur :
  - Création d’un compte Vault.
  - Rotation échouée.
  - Session PSM prolongée anormale.

---

## Références Normatives

| Réf. | Norme / Cadre | Domaine |
|------|----------------|---------|
| [1] | **NIST SP 800-53 rev5 – PR.AC-6** | Least Privilege |
| [2] | **NIST SP 800-60 rev1** | Guide mapping TI to Security Categories |
| [3] | **ISO/IEC 27001:2022 – A.9.4.3** | Use of privileged utilities |
| [4] | **CIS Controls v8 – Control 5** | Account Management |
| [5] | **Microsoft EAM** | Tiering & Access Segmentation |
| [6] | **CyberArk API Guide (v13.x)** | REST API Reference |
| [7] | **CyberArk PAM Architecture Hardening Guide v13.x** | PAM Hardening Reference |
