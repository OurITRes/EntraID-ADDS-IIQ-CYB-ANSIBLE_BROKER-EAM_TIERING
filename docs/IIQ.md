# SAILPOINT IIQ – Gouvernance des Identités et Orchestration Sécurisée

## 1. Introduction

SailPoint **IdentityIQ (IIQ)** constitue le **pilier central de gouvernance des identités** au sein de l’écosystème EntraID – ADDS – CyberArk – Ansible, dans un modèle fondé sur la **séparation des tiers (T0, T1, T2)** et les principes **Zero Trust**, **Least Privilege** et **Secure-by-Design**.

IIQ agit comme **source d’autorité** pour les identités métiers, assurant :
- le **provisionnement initial** des comptes utilisateurs standard (T2),
- la **gouvernance des rôles et droits d’accès**,
- la **revue périodique** et la **certification des accès**,
- la **coordination des flux JIT / PAM** avec CyberArk via un **orchestrateur T1**.

---

## 2. Cycle de vie d’une identité

L’ensemble du cycle de vie est contrôlé et auditable de bout en bout :

1. **Création HR Feed (T2)** – arrivée du collaborateur.
2. **Provisioning IIQ → EntraID / ADDS** – via connecteurs SCIM et LDAP.
3. **Attribution automatique de rôles** selon le modèle AGDLP et les politiques RBAC.
4. **Approbation via workflow IIQ** avec contrôle SoD (Segregation of Duties).
5. **Activation ou délégation JIT (T0/T1)** orchestrée via CyberArk PVWA API.
6. **Audit & revues périodiques** (certifications, réconciliations, logs).

Ce modèle assure une gouvernance **transversale**, centralisée et conforme aux normes NIST, ISO et CIS.

---

## 2bis. Architecture technique et composants

### 2.1 Composants internes

| Composant | Rôle | Tier | Description |
|------------|------|------|-------------|
| **Application Server (Tomcat)** | Exécution des workflows IIQ | T1 | Fournit les interfaces Web et API internes |
| **Identity Warehouse (DB)** | Stockage des identités, rôles et policies | T1 | Chiffrement des tables sensibles, TDE activé |
| **Workflow Engine** | Gestion des processus d’approbation et de provisioning | T1 | Utilise les triggers et connectors |
| **Connectors** | Interfaces vers EntraID, ADDS, CyberArk, Ansible | T1 | Connecteurs SCIM, LDAP, REST, SOAP |
| **Task Scheduler** | Lancement des jobs d’audit et de réconciliation | T1 | Exécution planifiée, supervision SIEM |

### 2.2 Schéma logique

```
[HR Feed] --> [IIQ Engine] --> [Connectors] --> [Entra ID / ADDS / CyberArk]
                               ^ 
                               |
                         [Ansible Broker]
```

---

## 3. Classification des flux IIQ

| Flux | Direction | Description | Sensibilité | Tier |
|------|------------|--------------|--------------|------|
| HR Feed → IIQ | Entrant | Création utilisateur standard | Standard | T2 |
| IIQ → Entra ID | Sortant | Provisioning SCIM / Graph API | Sensible | T1 |
| IIQ → ADDS | Sortant | Création / désactivation compte AD | Sensible | T1 |
| IIQ → Ansible Broker | Sortant | Appel workflow JIT (comptes admin) | Critique | T1→T0 |
| IIQ ← Audit / GRC | Sortant | Export logs & rapports conformité | Standard | T2 |

Chaque flux est journalisé dans `/logs/audit/IIQ-YYYYMMDD.log` et transmis au SIEM (lecture seule).

---

## 4. Sécurité et durcissement IIQ

SailPoint IIQ opère au **Tier 1**, dans une zone réseau isolée des DCs T0 et protégée par bastion.  
Les mesures de sécurité suivantes s’appliquent :

- **TLS 1.2+ obligatoire** sur toutes les communications.
- **Certificats X.509 signés** par une CA interne T1.
- **Comptes de service dédiés et non interactifs** pour les connecteurs.
- **Base de données chiffrée** (Transparent Data Encryption – TDE).
- **Rotation annuelle des clés et tokens d’accès.**
- **Audit des accès administratifs** (toutes actions IIQ_ADMIN loggées).
- **Logs d’application envoyés vers le SIEM** (Datadog / Splunk).
- **Protection OWASP A1-A10**, incluant validation d’entrée et tokens CSRF.
- **Séparation des environnements** : DEV / TST / PRD isolés.

---

## 5. Audit et conformité

L’audit repose sur une **traçabilité complète** des actions IIQ et une **collecte centralisée**.

### 5.1 Processus
1. IIQ exporte ses journaux d’événements dans `/audit/evidences/IIQ_*.json`.
2. Un **playbook Ansible** agrège et chiffre les logs avant transfert au coffre (Vault).
3. Les journaux sont vérifiés pour complétude et horodatage.
4. Un audit **trimestriel** est réalisé par le GRC Auditor.
5. Les résultats sont consolidés dans `reports/compliance_report.json`.

### 5.2 Objectifs
- Garantir la conformité **PR.AC-6 (Least Privilege)**.
- Démontrer le respect de **CIS Control 5** et **ISO A.9.4.3**.
- Assurer la non-altération des logs et la continuité du monitoring.

---

## 6. Rôles et responsabilités

| Rôle | Description | Tier | Responsabilités |
|------|--------------|------|----------------|
| **IIQ System Admin** | Supervise la plateforme et les connecteurs | T1 | Maintenance, patch, sécurité |
| **Access Approver** | Valide les demandes sensibles | T1 | Validation MFA, respect SoD |
| **Business Owner** | Détient l’application métier | T2 | Valide le besoin d’accès |
| **GRC Auditor** | Revoit la conformité | T1 | Vérifie les logs et certifications |
| **Orchestrator (Ansible)** | Intermédiaire API | T1 | Délègue les actions JIT à CyberArk |

---

## 7. Diagramme de séquence UML (Vue simplifiée)

```
participant HR
participant IIQ
participant Ansible
participant CyberArk
participant EntraID
participant ADDS

HR->IIQ: Création identité (HR Feed)
IIQ->EntraID: Provisioning SCIM
IIQ->ADDS: Provisioning LDAP
IIQ->Ansible: Appel workflow JIT
Ansible->CyberArk: Requête PVWA API
CyberArk->Vault: Rotation / Session JIT
IIQ->GRC: Export logs conformité
```

---

## 8. Gouvernance et bonnes pratiques

- Les flux IIQ doivent être documentés et approuvés avant mise en production.  
- Les rôles d’approbation doivent être **validés annuellement**.  
- Les workflows JIT doivent inclure **double validation MFA**.  
- IIQ doit s’intégrer au **processus de revue de comptes** semestriel.  
- Les connecteurs AD/EntraID/CyberArk doivent être **signés et versionnés**.  
- Les logs d’échec de provisioning sont à corréler avec ceux du SIEM.  

---

## 9. Références normatives

| Réf. | Norme / Cadre | Domaine |
|------|----------------|---------|
| [1] | **NIST SP 800-53 rev5 – PR.AC-6** | Least Privilege |
| [2] | **ISO/IEC 27001:2022 – A.9.4.3** | Use of privileged utilities |
| [3] | **CIS Controls v8 – Control 5** | Account Management |
| [4] | **Microsoft EAM** | Tiering & Access Segmentation |
| [5] | **SailPoint IIQ Administrator Guide v8.x** | Identity Governance Implementation |

---

**Fin du document – IIQ.md**
