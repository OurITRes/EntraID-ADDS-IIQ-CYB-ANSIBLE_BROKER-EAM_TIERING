# COMPLIANCE

## 1. Objectif et portée

Le présent document décrit le **cadre de conformité** de la plateforme intégrée **EntraID–ADDS–IIQ–CyberArk–Ansible**, alignée sur les référentiels **NIST CSF 2.0**, **ISO/IEC 27001:2022**, **CIS Controls v8**, **Microsoft EAM** et **GDPR/LPRPDE (Canada)**.  

L’objectif est triple :
- **Assurer la conformité continue** aux standards internationaux et obligations locales.  
- **Rendre la conformité vérifiable**, à travers des preuves techniques tangibles.  
- **Instaurer une amélioration continue**, via des revues, audits et plans d’action intégrés à la gouvernance (CSI / COS).

---

## 2. Cadres normatifs de référence

Les piliers de conformité utilisés comme base sont les suivants :

| Référence | Domaine | Objectif principal |
|------------|----------|--------------------|
| **NIST CSF 2.0** | Gouvernance & Résilience | Identifier, Protéger, Détecter, Répondre, Récupérer |
| **ISO/IEC 27001:2022** | Sécurité de l'information | Cadre global ISMS (Annexe A) |
| **CIS Controls v8** | Bonnes pratiques opérationnelles | 18 familles de contrôles de sécurité |
| **GDPR / LPRPDE** | Réglementation données personnelles | Droits des personnes, limitation du traitement |
| **Microsoft EAM** | Sécurité identitaire | Segmentation des privilèges et durcissement des accès |

La conformité ne se limite pas à cocher des cases : elle traduit une posture vivante, mesurable et vérifiable à tout moment.

---

## 3. Gouvernance de la conformité

### 3.1 Rôles et responsabilités
| Rôle | Responsabilité |
|------|----------------|
| **GRC Officer** | Supervise la conformité, gère les audits et les plans CAP |
| **CISO / Security Owner** | Valide les risques résiduels et les écarts critiques |
| **IAM Manager (IIQ)** | Gère la conformité des identités et des rôles |
| **CyberArk Vault Manager** | Contrôle la conformité des accès à privilèges |
| **SOC Manager** | Fournit les preuves issues des journaux de sécurité |
| **DPO / Privacy Officer** | Supervise la conformité aux lois sur les données personnelles |

### 3.2 Processus d’audit et de revue
Chaque trimestre :
- les logs IIQ, CyberArk, Entra ID et ADDS sont consolidés,  
- un rapport de conformité automatisé est généré (`/reports/compliance_report.json`),  
- les écarts identifiés déclenchent un **Corrective Action Plan (CAP)** validé en **COS**.

---

## 4. Cycle de conformité

La conformité suit un **cycle continu à 6 phases**, représenté ci-dessous :

> **Contrôle → Preuve → Audit → Action → Revue → Amélioration continue**

Chaque solution de la plateforme contribue à ce cycle.

| Étape | Description | Outils impliqués |
|--------|--------------|------------------|
| **Contrôle** | Application des politiques et restrictions | Entra ID, CyberArk, ADDS |
| **Preuve** | Collecte et journalisation des événements | IIQ, Splunk, Datadog |
| **Audit** | Vérification de la conformité aux référentiels | PingCastle, CIS, GRC Reports |
| **Action** | Traitement des écarts, CAP | Ansible, GitHub Actions |
| **Revue** | Validation des remédiations par comité COS | CSI / GRC |
| **Amélioration continue** | Mise à jour des politiques et procédures | CAB, IAM, SecOps |

---

## 5. Mappage des contrôles aux solutions

### 5.1 IIQ – Identity Governance
| Contrôle | Référence | Objectif | Preuve |
|-----------|-------------|-----------|--------|
| Provisioning contrôlé | NIST PR.AC-1 / ISO A.9.2.6 | Garantir que tout accès est approuvé | Logs LCM, Workflow IIQ |
| Revue périodique des accès | CIS 6.3 / ISO A.9.2.5 | Assurer la validité des accès | Rapports Certification IIQ |
| Séparation des rôles (SoD) | NIST PR.AC-5 | Empêcher les cumuls dangereux | Analyse de conflit SoD |

### 5.2 CyberArk – Privileged Access
| Contrôle | Référence | Objectif | Preuve |
|-----------|-------------|-----------|--------|
| Gestion des sessions privilégiées | NIST PR.AC-6 / CIS 5.1 | Isoler et tracer les accès à privilèges | Journaux PSM / PVWA |
| Rotation automatique des mots de passe | ISO A.9.4.3 | Réduire le risque d’exposition | Logs Vault rotation |
| Accès Just-In-Time (JIT) | CIS 6.8 | Supprimer les privilèges permanents | Activations JIT / PIM |

### 5.3 Entra ID – Cloud Identity
| Contrôle | Référence | Objectif | Preuve |
|-----------|-------------|-----------|--------|
| Authentification MFA | NIST PR.AC-7 / ISO A.9.4.2 | Empêcher l’usurpation d’identité | Logs AzureADSignIn |
| Conditional Access | NIST PR.IP-1 | Limiter les accès selon le contexte | Policies export JSON |
| PIM (Privileged Identity Management) | CIS 5.4 | Réduire l’exposition des rôles admin | Export activations PIM |

### 5.4 ADDS – Directory On-prem
| Contrôle | Référence | Objectif | Preuve |
|-----------|-------------|-----------|--------|
| GPO durcissement | CIS 18 / NIST PR.IP-1 | Configurer les DC selon le CIS Benchmark | Rapport PingCastle |
| AdminSDHolder / ACL | ISO A.9.1.2 | Restreindre les permissions sensibles | Audit PowerShell ADACL |
| FGPP / Policies | NIST PR.AC-1 | Appliquer les règles de mot de passe différenciées | GPMC export XML |

### 5.5 Ansible / GitHub Actions – Automatisation
| Contrôle | Référence | Objectif | Preuve |
|-----------|-------------|-----------|--------|
| Traçabilité des changements | ISO A.12.1.2 / CIS 11.1 | Enregistrer toute modification d’infrastructure | Logs CI/CD GitHub |
| Validation par pairs (Pull Request) | NIST PR.IP-3 | Prévenir les erreurs humaines | Journal de merge Git |
| Remédiation automatisée | CIS 8.2 | Corriger automatiquement les écarts | Playbook Ansible CAP |

---

## 6. Vérification et auditabilité

La conformité repose sur la capacité à **démontrer** la mise en œuvre d’un contrôle par une **preuve technique**.

### 6.1 Types d’évidences
- Export JSON des politiques Entra ID (`/exports/entra_policies/`)  
- Rapports IIQ Certification (`/reports/iiq_certification.csv`)  
- Logs CyberArk (`/vault/logs/psm_sessions.json`)  
- Rapports PingCastle et CIS Benchmarks (`/reports/audit/`)  

### 6.2 Audit Trails et Logs
Tous les journaux sont centralisés dans Splunk via syslog et API, puis corrélés à l’aide de tableaux de bord GRC (Grafana / Power BI).

### 6.3 Rapports automatisés
Les pipelines GitHub génèrent automatiquement :
- `/reports/compliance_report.json`  
- `/reports/iso27001_matrix.csv`  
- `/reports/nist_csf_status.md`

---

## 7. Conformité aux cadres de sécurité – Mappage global

| Domaine NIST CSF | ISO/IEC 27001:2022 | CIS Control | Outils associés |
|------------------|--------------------|--------------|-----------------|
| **Identify (ID)** | A.5.1, A.6.1 | CIS 1, 2 | IIQ, Governance, GRC |
| **Protect (PR)** | A.8, A.9 | CIS 4, 5, 6 | CyberArk, Entra ID, ADDS |
| **Detect (DE)** | A.12, A.13 | CIS 7, 8 | SOC, Splunk, Defender |
| **Respond (RS)** | A.17 | CIS 10 | Ansible, GitHub Actions |
| **Recover (RC)** | A.17, A.18 | CIS 11, 13 | ADDS, Backup, PRA |
| **Compliance / Privacy** | A.18 | CIS 16 | IIQ, GRC, DPO |

---

## 8. Non-conformités et plans correctifs (CAP)

| ID | Référence | Description | Impact | Responsable | Statut | Échéance |
|----|-------------|-------------|---------|--------------|----------|-----------|
| CAP-001 | ISO A.9.2.6 | Absence de revue trimestrielle des accès IIQ | Moyen | IAM | En cours | 2025-11-30 |
| CAP-002 | NIST PR.AC-6 | Sessions PSM non clôturées automatiquement | Élevé | CyberArk | Ouvert | 2025-10-20 |
| CAP-003 | CIS 8.2 | Absence d’audit automatisé post-remédiation | Moyen | SecOps | En cours | 2025-12-15 |

Chaque CAP fait l’objet d’un suivi COS mensuel et d’une validation CSI semestrielle.  
Les rapports CAP sont stockés dans `/plans/remediation/`.

---

## 9. Indicateurs de conformité (KCI)

| KCI | Objectif | Seuil | Responsable | Source |
|------|-----------|--------|--------------|---------|
| % de contrôles conformes NIST CSF | ≥ 95 % | > 90 % | GRC | compliance_report.json |
| % de comptes MFA activés | 100 % | < 100 % = alerte | IAM | Entra ID Logs |
| % de revues d’accès complètes | 100 % | < 95 % = CAP | IAM / GRC | IIQ |
| % de CAP clôturés à temps | 100 % | < 90 % = alerte CSI | GRC | CAP Tracker |
| % de conformité GDPR (PII anonymisées) | ≥ 98 % | < 95 % = audit | DPO | SOC / SIEM |

---

## 10. Annexes

- `/reports/compliance_report.json`  
- `/exports/entra_policies/`  
- `/reports/iso27001_matrix.csv`  
- `/plans/remediation/`  

---

## Références normatives

| Réf. | Norme / Cadre | Description |
|------|----------------|-------------|
| [1] | **NIST CSF 2.0** | Cadre principal de cybersécurité et de gouvernance |
| [2] | **ISO/IEC 27001:2022** | Système de management de la sécurité |
| [3] | **CIS Controls v8** | Bonnes pratiques de contrôle technique |
| [4] | **GDPR / LPRPDE** | Protection des données personnelles |
| [5] | **Microsoft EAM** | Tiering et gouvernance des identités |
| [6] | **ITIL v4** | Processus d’amélioration continue |
| [7] | **ISO/IEC 27005:2022** | Gestion du risque de conformité |
