# AUDIT

## 1. Objectif et portée

Le présent document décrit la **stratégie et le processus d’audit** de la plateforme **EntraID–ADDS–IIQ–CyberArk–Ansible**, intégrée dans le cadre de gouvernance de la sécurité et de la conformité de l’organisation.  

L’audit est perçu ici non pas comme une contrainte ponctuelle, mais comme un **mécanisme vivant** au service de la **maîtrise des risques, de la transparence et de la confiance**.  

Ce cadre s’applique à :
- tous les environnements (**DEV**, **TST**, **PRD**),  
- tous les tiers de sécurité (**T0 à T2**),  
- et à toutes les entités techniques et organisationnelles impliquées dans la gestion des identités, des privilèges, de la conformité et des infrastructures associées.

---

## 2. Typologie des audits

### 2.1 Audits internes
Les audits internes sont conduits par la fonction **GRC (Governance, Risk & Compliance)** en coordination avec le **CISO**, le **SOC** et les équipes **IAM / SecOps**.  
Leur objectif est de :
- vérifier la conformité aux politiques internes,  
- évaluer la performance des contrôles techniques,  
- anticiper les écarts avant les audits externes.

Les résultats sont présentés trimestriellement au **Comité Opérationnel de Sécurité (COS)**.

### 2.2 Audits externes
Les audits externes sont menés par des tiers indépendants (accrédités ISO / SOC2 / PCI-DSS).  
Ils visent à :
- certifier la conformité réglementaire et normative,  
- valider la robustesse du système de contrôle interne,  
- fournir une assurance indépendante au conseil d’administration et aux parties prenantes.

### 2.3 Audits techniques automatisés
Ils complètent les audits manuels par des analyses continues :
- **PingCastle** (hygiène et vulnérabilité ADDS),  
- **CIS Benchmark** (durcissement OS et configurations),  
- **IIQ Certification Reports**,  
- **CyberArk Vault Reports**,  
- **Entra ID Conditional Access reviews**.  

Ces audits automatisés alimentent en continu le tableau de bord **GRC Power BI** et le registre `/audit/reports/`.

---

## 3. Gouvernance de l’audit

### 3.1 Rôles et responsabilités
| Rôle | Responsabilité |
|------|----------------|
| **CISO** | Définit la stratégie d’audit et approuve les plans annuels |
| **GRC Officer** | Coordonne les campagnes d’audit, centralise les résultats |
| **Auditeur interne** | Exécute les revues techniques et organisationnelles |
| **Auditeur externe** | Valide la conformité et la robustesse des contrôles |
| **SOC Manager** | Fournit les logs, corrélations et incidents associés |
| **IAM Manager** | Valide la conformité des rôles, workflows et SoD |
| **CyberArk Admin** | Fournit les preuves PSM/PVWA et les rapports de rotation |
| **DPO** | Vérifie les aspects de conformité GDPR / LPRPDE |

### 3.2 Fréquence et périmètre
| Type d’audit | Fréquence | Périmètre | Responsable |
|---------------|------------|------------|--------------|
| Interne technique | Trimestriel | IIQ / ADDS / Entra / CyberArk | GRC |
| Interne gouvernance | Semestriel | Processus, rôles, RACI | CISO |
| Externe certification | Annuel | Conformité ISO / SOC2 / GDPR | Auditeur externe |
| Automatisé | Continu | CIS / PingCastle / PSM / SIEM | SOC / SecOps |

---

## 4. Processus d’audit (cycle narratif)

L’audit est conçu comme un **cycle vivant**, structuré autour de cinq étapes majeures :

> **Préparer → Exécuter → Collecter → Restituer → Améliorer**

### 4.1 Préparer
Tout commence par la planification.  
Le GRC établit le **Plan d’audit annuel** (PAA) à partir des risques identifiés dans le registre et des priorités du CSI.  
Les périmètres, échéances et ressources sont validés en comité COS.  
Un “scope document” formel est publié dans `/audit/plans/`.

### 4.2 Exécuter
Les auditeurs collectent les éléments techniques et organisationnels :
- exports IIQ (users, roles, entitlements),  
- rapports CyberArk (PSM, Safe Policies),  
- logs Entra ID (sign-ins, Conditional Access),  
- configurations ADDS (ACL, FGPP, GPO).  

Chaque test est exécuté selon un protocole d’audit interne fondé sur les standards **ISO 19011** et **NIST SP 800-115**.

### 4.3 Collecter
Les **preuves d’audit (evidences)** sont enregistrées sous forme de fichiers :
- `.json` (exports API),  
- `.csv` (rapports),  
- `.log` (journaux horodatés),  
- `.pdf` (rapports d’audit externes).  

Toutes les preuves sont stockées dans `/audit/evidences/`, signées numériquement et référencées dans le **registre de conformité** (`/reports/compliance_report.json`).

### 4.4 Restituer
Les constats sont classés en 4 niveaux :
| Niveau | Gravité | Description | Action requise |
|---------|----------|-------------|----------------|
| 1 | Mineur | Observation sans risque immédiat | Suivi dans GRC |
| 2 | Modéré | Écart procédural | CAP planifié |
| 3 | Majeur | Risque opérationnel | CAP prioritaire |
| 4 | Critique | Non-conformité sévère | Escalade CSI / Board |

Chaque rapport d’audit est diffusé au format Markdown et PDF dans `/audit/reports/`, avec un **sommaire exécutif** pour les comités et une **analyse technique** pour les équipes.

### 4.5 Améliorer
Les résultats sont consolidés dans le **registre GRC**, et les **Corrective Action Plans (CAP)** sont ouverts automatiquement dans `/plans/remediation/`.  
Chaque plan fait l’objet d’un suivi COS mensuel et d’une validation CSI semestrielle.  
Les leçons apprises alimentent le **cycle d’amélioration continue**.

---

## 5. Collecte et gestion des preuves

### 5.1 Sources de données
| Domaine | Source | Type de preuve |
|----------|---------|----------------|
| Identité | IIQ | CSV exports (certifications, SoD) |
| Privilèges | CyberArk | JSON (Vault, PSM, Safe Policies) |
| Cloud | Entra ID | Logs Conditional Access / Sign-In |
| Annuaire | ADDS | Rapports PowerShell / PingCastle |
| Infrastructure | Ansible / Terraform | Fichiers de configuration / journaux CI/CD |

### 5.2 Formats et conservation
Toutes les preuves sont conservées pour **minimum 3 ans** dans un stockage chiffré, partitionné par année et environnement.  
Les fichiers sont horodatés et compressés (`tar.gz`) selon le schéma :
```
/audit/evidences/YYYY/MM/DD/{source}_{type}_{env}.json
```
Les clés de signature sont gérées par le **CISO** et le **GRC Officer**.

### 5.3 Intégration GRC et SOC
Les données d’audit sont corrélées avec :
- les tickets Jira (suivi CAP),  
- les incidents Splunk,  
- les indicateurs KCI/KRI issus de `COMPLIANCE.md` et `RISK_MANAGEMENT.md`.  

Cette intégration garantit une **vision à 360°** de la posture réelle de sécurité.

---

## 6. Automatisation et pipelines d’audit

L’automatisation des audits repose sur des **workflows GitHub Actions** et **Playbooks Ansible** exécutés selon un calendrier prédéfini.  
Les résultats (rapports JSON, logs, comparatifs CIS) sont automatiquement exportés dans `/audit/reports/` et validés par le GRC.  

Exemples d’audits automatisés :
- **Audit IIQ LCM** : vérifie la cohérence des workflows et rôles SoD.  
- **Audit CyberArk Vault** : valide la rotation automatique des mots de passe.  
- **Audit Entra ID Policies** : compare les policies JSON à la baseline.  
- **Audit ADDS PingCastle** : vérifie la santé et l’exposition des DC.  

Chaque exécution génère :
- un **rapport d’état (status.json)**,  
- un **diff baseline / courant**,  
- et une **alerte** si un écart critique est détecté.

---

## 7. Posture d’auditabilité et traçabilité

Une organisation **auditable** est une organisation **prévisible et transparente**.  
Dans cette architecture, l’auditabilité repose sur :
- la **centralisation des logs**,  
- la **corrélation multi-niveau** (identité, privilèges, infrastructure),  
- la **traçabilité intégrale** des actions humaines et automatisées,  
- la **signature des rapports et preuves** (hash SHA256).  

Les rapports d’audit sont non seulement produits, mais **reproductibles**, garantissant une traçabilité complète des contrôles.

---

## 8. Plan d’audit annuel (PAA)

Le plan annuel d’audit est révisé chaque début d’année et validé par le **Comité Stratégique d’Information (CSI)**.  

| Trimestre | Domaine audité | Responsable | Type | Outils principaux |
|------------|----------------|--------------|------|-------------------|
| Q1 | Identité & Accès (IIQ / Entra) | GRC / IAM | Interne | IIQ Reports / Entra Logs |
| Q2 | Privilèges & Bastions (CyberArk / ADDS) | CISO / SOC | Technique | CyberArk / PingCastle |
| Q3 | Conformité & Données personnelles | DPO / GRC | Externe | GDPR Audit / GRC Portal |
| Q4 | Continuité & PRA | IT Ops / GRC | Interne | Terraform / PRA Runbooks |

---

## 9. Annexes et référentiels

- `/audit/reports/` – Rapports d’audit annuels et trimestriels  
- `/audit/evidences/` – Dossiers de preuves collectées  
- `/plans/remediation/` – Corrective Action Plans (CAP)  
- `/reports/compliance_report.json` – Consolidation GRC  
- `/governance/policies/` – Références de gouvernance applicables  

---

## Références normatives

| Réf. | Norme / Cadre | Description |
|------|----------------|-------------|
| [1] | **ISO 19011:2018** | Lignes directrices pour l’audit des systèmes de management |
| [2] | **NIST SP 800-115** | Technical Guide to Information Security Testing and Assessment |
| [3] | **ISO/IEC 27001:2022** | Contrôles et exigences d’audit ISMS |
| [4] | **CIS Controls v8** | Vérification de l’efficacité des mesures techniques |
| [5] | **SOC 2 Type II** | Cadre de contrôle interne basé sur la confiance |
| [6] | **Microsoft EAM** | Répartition des audits selon le tiering |
| [7] | **ITIL v4** | Amélioration continue des audits et processus GRC |
