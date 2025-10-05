# GOVERNANCE

## 1. Objectif et portée de la gouvernance

La gouvernance de la plateforme **EntraID–ADDS–IIQ–CyberArk–Ansible** a pour but d’assurer la **cohérence, la transparence et la responsabilité** dans toutes les décisions techniques, organisationnelles et sécuritaires.  
Elle s’applique à l’ensemble des environnements (**DEV**, **TST**, **PRD**) et à tous les niveaux du modèle **Enterprise Access Model (EAM)** — du **Tier 0** (infrastructure critique) au **Tier 2** (services utilisateurs).

Ses objectifs sont :
- Aligner les décisions techniques avec la stratégie d’entreprise et les objectifs de sécurité.  
- Garantir une traçabilité complète des décisions et des changements.  
- Assurer la conformité continue aux référentiels normatifs et réglementaires (NIST CSF 2.0, ISO/IEC 27001, ISO 20000, ITIL v4, GDPR).  
- Encadrer les responsabilités de chaque acteur — Business, IT, IAM, Sécurité, GRC, SOC.

---

## 2. Modèle de gouvernance de la plateforme

La gouvernance s’articule sur **trois niveaux complémentaires**, inspirés des meilleures pratiques **COBIT** et **ISO 27014**.

| Niveau | Rôle principal | Exemples d’activités |
|---------|----------------|----------------------|
| **Stratégique** | Fixe la vision et les priorités | Définition des objectifs de sécurité, arbitrages budgétaires |
| **Tactique** | Traduit la stratégie en plans d’action | Gestion des risques, conformité, approbation des projets |
| **Opérationnel** | Exécute et contrôle les opérations | Administration quotidienne, surveillance, audits techniques |

Ces niveaux sont liés par un flux de gouvernance descendant et remontant :  
la stratégie fixe le cadre, les opérations remontent les indicateurs et les écarts,  
et la gouvernance ajuste en continu.

---

### 2.1 Rôles clés et responsabilités

| Rôle | Responsabilités principales |
|------|------------------------------|
| **Business Owner** | Définit les besoins métier, valide les risques résiduels |
| **IT Owner** | Gère la disponibilité, la performance et l’évolution technique |
| **Security Owner (CISO)** | Supervise la posture de sécurité globale |
| **IAM Manager (IIQ)** | Gère les identités, les rôles et la conformité d’accès |
| **CyberArk Vault Manager** | Supervise la sécurité des comptes à privilèges |
| **SOC Manager** | Assure la détection, la réponse et la corrélation des incidents |
| **GRC Officer** | Suit les audits, la conformité et les obligations réglementaires |
| **Change Advisory Board (CAB)** | Valide les changements majeurs, planifie leur déploiement |

---

## 3. Structure de comités et processus décisionnels

Trois comités assurent le pilotage et la supervision continue du programme identitaire.

### 3.1 Comité Stratégique Identité (CSI)
- Périmètre : gouvernance globale, priorités d’entreprise, conformité réglementaire.  
- Fréquence : trimestrielle.  
- Membres : Direction Sécurité, DSI, GRC, Représentants métiers.  
- Livrables : feuilles de route, approbation des budgets, orientations stratégiques.

### 3.2 Comité Opérationnel Sécurité (COS)
- Périmètre : suivi des risques, incidents, indicateurs SOC.  
- Fréquence : mensuelle.  
- Membres : SOC Manager, CyberArk, IAM, CISO adjoint.  
- Livrables : rapport de posture sécurité, recommandations d’amélioration.

### 3.3 Comité Technique Cloud / ADDS (CTC)
- Périmètre : coordination technique, architecture, performance et intégrations.  
- Fréquence : bi-hebdomadaire.  
- Membres : Architectes ADDS, Admins Entra, DevOps, SecOps.  
- Livrables : CR techniques, schémas, décisions d’implémentation.

---

## 4. Gestion du changement (Change Management)

Les changements suivent le cadre **ITIL v4** et sont catégorisés selon leur impact.

| Type de changement | Exemple | Processus d’approbation |
|---------------------|----------|-------------------------|
| **Standard** | Patch ADDS, mise à jour Ansible mineure | Validation Ops + CTC |
| **Normal** | Ajout d’un connecteur IIQ ou d’une politique CA | CAB + COS |
| **Urgent** | Contournement sécurité / vulnérabilité critique | CSI + CISO + SOC |

Chaque changement est documenté dans le dépôt GitHub sous `/changes/` avec :  
- description, justification, impacts,  
- approbations électroniques (workflow GitHub Actions),  
- validation finale avant déploiement PRD.

---

## 5. Conformité et audit

### 5.1 Cadres normatifs appliqués
Les normes et cadres suivants guident la gouvernance :
- **NIST CSF 2.0** : structure principale du modèle de maturité.  
- **ISO/IEC 27001:2022** : exigences de gouvernance de la sécurité.  
- **CIS Controls v8** : référence de durcissement et d’opérations.  
- **ITIL v4** : bonnes pratiques de service management.  
- **GDPR (UE)** : conformité à la protection des données.  

### 5.2 Plan d’audit interne
- **Audit semestriel** : conformité NIST / CIS sur les environnements T0–T2.  
- **Audit annuel** : contrôle des processus ITIL / ISO 20000.  
- **Audit à la demande** : suite à un incident majeur ou une recommandation COS.  

Tous les audits sont archivés dans `/audit/reports/` avec leur plan d’action associé.

---

## 6. Gestion du risque et suivi des non-conformités

Les risques sont suivis dans le **registre de risques** (`/risks/risks_register.xlsx`) selon trois axes :
- **Probabilité (P)**, **Impact (I)** et **Niveau résiduel (R)**.  
- Chaque risque critique (R > 15) fait l’objet d’un plan d’atténuation et d’une validation CSI.  
- Les non-conformités identifiées en audit sont classées selon leur sévérité et suivies via Ansible Automation Controller (tickets “remediation”).

---

## 7. Ownership et modèle RACI global

| Activité | Business Owner | IT Owner | Security Owner | IAM | CyberArk | SOC | GRC |
|-----------|----------------|-----------|----------------|-----|-----------|-----|-----|
| Gouvernance stratégique | **A** | C | **R** | I | I | C | C |
| Gestion des accès (IIQ) | I | C | C | **R** | I | I | **A** |
| Gestion des comptes à privilèges | I | I | C | C | **R** | C | **A** |
| Surveillance SOC | I | I | C | I | C | **R** | A |
| Maintenance ADDS | I | **R** | C | I | C | I | - |
| Sécurité cloud (Entra ID) | I | C | **R** | C | I | C | A |
| Conformité réglementaire | **R** | C | C | I | I | C | **A** |
| Changement critique | **A** | **R** | **C** | C | I | C | C |

Légende : **R = Responsible**, **A = Accountable**, **C = Consulted**, **I = Informed**

---

## 8. Alignement stratégique (objectifs d’affaires et KPIs)

Le modèle de gouvernance associe les **objectifs business** aux **indicateurs techniques mesurables**.

| Objectif métier | KPI clé | Indicateur technique | Responsable |
|------------------|----------|----------------------|--------------|
| Réduction du risque de privilèges permanents | % comptes JIT vs statiques | Activations PIM & CyberArk JIT | IAM / CISO |
| Renforcement de la conformité réglementaire | % conformité ISO/NIST | Rapports IIQ / PingCastle / GRC | GRC Officer |
| Optimisation de la productivité IT | Temps moyen de provisioning | Logs IIQ + Ansible Jobs | IT Owner |
| Amélioration du temps de réponse incident | MTTR < 60 min | SOC Dashboard Splunk | SOC Manager |
| Amélioration de la visibilité multi-tenant | % couverture des logs SIEM | Splunk index coverage | SecOps |
| Réduction du coût opérationnel | % d’automatisation des tâches récurrentes | Jobs Ansible / GitHub Actions | Infra Ops |

Ces indicateurs sont suivis mensuellement via **Grafana** et présentés en **Comité Stratégique Identité (CSI)**.

---

## 9. Reporting et tableaux de bord de gouvernance

- **Dashboard CSI** : avancement des projets, indicateurs clés, suivi des risques.  
- **Dashboard COS** : posture sécurité, taux de conformité, incidents détectés.  
- **Dashboard CTC** : taux de succès des déploiements IaC, backlog d’automatisation.  
Les tableaux de bord sont hébergés dans `/dashboards/governance/` et alimentés automatiquement par **Grafana / Power BI / Splunk**.

---

## 10. Annexes

- Modèle d’ordre du jour de comité (`/templates/agenda.md`)  
- Tableau de suivi des décisions (`/governance/decisions_register.csv`)  
- Registre des risques (`/risks/risks_register.xlsx`)  
- Plan d’audit (`/audit/audit_plan.md`)

---

## Références normatives

| Réf. | Norme / Cadre | Description |
|------|----------------|-------------|
| [1] | **NIST CSF 2.0** | Cadre de gouvernance et de gestion du risque |
| [2] | **ISO/IEC 27014** | Gouvernance de la sécurité de l'information |
| [3] | **ITIL v4** | Gestion des services et des changements |
| [4] | **ISO/IEC 20000** | Gouvernance IT et pilotage de service |
| [5] | **COBIT 2019** | Gouvernance d’entreprise et alignement stratégique |
| [6] | **NIST SP 800-37 rev2** | Gestion du risque et RMF |
| [7] | **GDPR (UE)** | Protection des données personnelles |
