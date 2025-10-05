# RISK MANAGEMENT

## 1. Objectif et portée

Le présent document définit le cadre, les processus et les outils de **gestion du risque** pour la plateforme intégrée **EntraID–ADDS–IIQ–CyberArk–Ansible**, structurée selon le modèle **Enterprise Access Model (EAM)**.  
Il s’applique à tous les environnements (**DEV**, **TST**, **PRD**) et à tous les tiers (**T0–T2**).

L’objectif est d’assurer :
- une **identification proactive** des risques techniques, organisationnels et de conformité ;  
- une **évaluation homogène** selon les critères Probabilité × Impact = Risque (P×I=R) ;  
- une **maîtrise documentée** des mesures de mitigation et de suivi ;  
- un **pilotage cohérent** des risques via les comités COS et CSI ;  
- une **traçabilité complète** entre les constats d’audit, les incidents et les plans de remédiation.

---

## 2. Cadre de gestion des risques

Le cadre s’appuie sur les référentiels :
- **NIST SP 800-37 rev2 (RMF)** – Risk Management Framework,  
- **ISO/IEC 27005:2022** – Gestion des risques liés à la sécurité de l’information,  
- **ISO 31000:2018** – Principes et lignes directrices,  
- **CIS Controls v8** – Mesures concrètes de maîtrise,  
- **Microsoft EAM** – Modèle de segmentation et de réduction du risque par tiering.

Le principe directeur est le suivant :  
> “Aucun risque n’est acceptable s’il peut être maîtrisé par conception, automatisation ou gouvernance.”

---

## 3. Processus de gestion du risque

### 3.1 Identification
Les risques sont identifiés à partir de :
- audits techniques (PingCastle, CIS Benchmark, IIQ Certification, CyberArk reports),  
- incidents remontés par le SOC,  
- changements d’architecture ou d’organisation,  
- revues trimestrielles COS et semestrielles CSI.

### 3.2 Évaluation (P × I × R)
Chaque risque est noté sur une échelle de 1 à 5 :
| Niveau | Probabilité | Impact | Niveau global (R = P×I) |
|---------|--------------|--------|--------------------------|
| 1 | Très faible | Mineur | 1–4 : Acceptable |
| 2 | Faible | Modéré | 5–9 : Toléré avec surveillance |
| 3 | Moyenne | Significatif | 10–14 : À mitiger |
| 4 | Élevée | Majeur | 15–19 : Critique |
| 5 | Très élevée | Catastrophique | 20–25 : Intolérable |

### 3.3 Traitement
Les traitements possibles sont :
- **Mitigation** (réduction par contrôle technique ou process),  
- **Transfert** (assurance ou externalisation),  
- **Évitement** (changement d’architecture),  
- **Acceptation** (risque documenté et approuvé par CSI).

### 3.4 Suivi et revue
Chaque risque fait l’objet :
- d’un **propriétaire désigné (Risk Owner)**,  
- d’un **plan de remédiation**,  
- d’une **échéance de revue**,  
- d’un **statut (Ouvert, En cours, Clos, Accepté)**.  

---

## 4. Typologie des risques

### 4.1 Risques techniques
- **R-001 : Compromission d’un compte à privilèges T0**  
  Cause : défaillance PSM ou accès direct non supervisé.  
  Conséquence : contrôle total de la forêt ADDS.  
  Mitigation : CyberArk + MFA + PAW + segmentation réseau.  

- **R-002 : Mauvaise synchronisation IIQ → Entra ID / ADDS**  
  Cause : erreur de SCIM / Graph API, données incohérentes.  
  Conséquence : droits résiduels ou suppression non contrôlée.  
  Mitigation : validation par workflow + tests automatiques Ansible.  

- **R-003 : Échec du PRA ADDS ou perte d’un DC primaire**  
  Cause : snapshot corrompu ou réplication interrompue.  
  Mitigation : PRA trimestriel, tests Terraform, double site DR.  

### 4.2 Risques organisationnels
- **R-010 : Manque de formation des opérateurs SOC / IAM**  
  Impact : erreurs d’analyse ou délais accrus.  
  Mitigation : plan de montée en compétence trimestriel COS.  

- **R-011 : Non-respect du tiering EAM dans les workflows**  
  Impact : escalade de privilèges accidentelle.  
  Mitigation : contrôles Ansible pré-déploiement + validation CAB.  

### 4.3 Risques de conformité
- **R-020 : Données personnelles exposées via logs ou sauvegardes**  
  Référence : GDPR / NIST PR.DS-5.  
  Mitigation : anonymisation et rotation automatique via scripts SOC.  

- **R-021 : Absence de traçabilité des changements d’accès**  
  Mitigation : intégration IIQ ↔ GitHub Actions ↔ GRC Audit Trail.  

---

## 5. Matrice de criticité (P × I)

| Impact → / Probabilité ↓ | 1 | 2 | 3 | 4 | 5 |
|---------------------------|---|---|---|---|---|
| **1 (Très faible)** | 1 | 2 | 3 | 4 | 5 |
| **2 (Faible)** | 2 | 4 | 6 | 8 | 10 |
| **3 (Moyenne)** | 3 | 6 | 9 | 12 | 15 |
| **4 (Élevée)** | 4 | 8 | 12 | 16 | 20 |
| **5 (Très élevée)** | 5 | 10 | 15 | 20 | 25 |

L’échelle de lecture :
- **1–4 : Vert** → Risque faible  
- **5–9 : Jaune** → Surveillance  
- **10–14 : Orange** → Mitigation requise  
- **15–25 : Rouge** → Risque critique, revue COS immédiate

---

## 6. Cartographie des risques

| ID | Domaine | Description | P | I | R | Niveau | Statut | Propriétaire | Plan d’action | Échéance |
|----|----------|--------------|---|---|---|---------|---------|---------------|----------------|-----------|
| R-001 | Sécurité | Compromission d’un compte T0 | 4 | 5 | 20 | Critique | En cours | CISO | Audit des accès PSM / renforcement MFA | 2025-10-30 |
| R-002 | Identité | Erreur SCIM IIQ → Entra ID | 3 | 4 | 12 | Élevé | En cours | IAM Manager | Tests unitaires Ansible + QA intégrée | 2025-11-15 |
| R-003 | Infrastructure | Échec PRA ADDS | 3 | 5 | 15 | Critique | Ouvert | IT Ops | Revue des scripts de réplication | 2025-12-01 |
| R-010 | Organisation | Manque de formation SOC/IAM | 2 | 3 | 6 | Modéré | En cours | GRC Officer | Programme de formation trimestriel | 2026-01-10 |
| R-011 | Gouvernance | Bypass du tiering EAM | 4 | 4 | 16 | Critique | Ouvert | CISO | Audit IIQ + validation Ansible | 2025-10-20 |
| R-020 | Conformité | Données personnelles exposées | 2 | 5 | 10 | Élevé | En cours | GRC Officer | Masquage logs + rotation sauvegardes | 2025-11-05 |
| R-021 | Audit | Absence de traçabilité des changements | 3 | 3 | 9 | Modéré | Clos | Audit interne | Mise en place audit trail IIQ | 2025-09-10 |

---

## 7. Gouvernance et revue des risques

Les risques critiques (R≥15) sont **revus mensuellement en Comité COS**, puis **présentés au CSI** pour validation ou acceptation formelle.  
Le **registre de risques** est maintenu dans `/risks/risks_register.xlsx` et synchronisé avec le **Power BI “Risk Dashboard”**.  

Chaque comité dispose :
- d’un **suivi des risques ouverts** (COS),  
- d’un **rapport de tendances et de résiduel** (CSI),  
- d’un **lien vers les plans de remédiation** (GRC/SOC).

---

## 8. Plans de remédiation et suivi

Chaque plan suit une structure standardisée :
| Étape | Description | Responsable | Validation |
|--------|--------------|--------------|-------------|
| **Identification** | Risque confirmé, assigné à un owner | COS | CSI |
| **Mitigation** | Mesures techniques / organisationnelles appliquées | Owner | COS |
| **Contrôle** | Vérification de l’efficacité des actions | SOC / Audit | GRC |
| **Clôture** | Risque ramené sous le seuil tolérable | CSI | GRC |

Les plans en retard ou inefficaces déclenchent un **Corrective Action Plan (CAP)** supervisé par GRC.

---

## 9. Indicateurs de risque clés (KRI)

| KRI | Description | Seuil d’alerte | Responsable | Source |
|------|--------------|----------------|--------------|---------|
| % de risques critiques ouverts > 90 j | Indique une inertie de remédiation | > 10 % | GRC Officer | Power BI Risk Dashboard |
| % d’incidents liés à des privilèges permanents | Corrélation IAM / SOC | > 5 % | SOC Manager | Splunk + IIQ |
| Temps moyen de traitement d’un risque | Délai moyen d’atténuation | > 45 j | CSI | GRC Tracker |
| % de risques techniques non audités | Retard d’audit PingCastle | > 5 % | Audit interne | PingCastle |
| Couverture du PRA ADDS | % DC testés / totaux | < 90 % | IT Ops | Grafana |

---

## 10. Annexes

- `/risks/risks_register.xlsx` : registre principal avec P, I, R, Owner, CAP  
- `/dashboards/risk_dashboard.pbix` : visualisation Power BI  
- `/audit/reports/` : rapports d’audit associés  
- `/plans/remediation/` : documentation des CAP

---

## Références normatives

| Réf. | Norme / Cadre | Description |
|------|----------------|-------------|
| [1] | **NIST SP 800-37 rev2** | Risk Management Framework |
| [2] | **ISO/IEC 27005:2022** | Gestion du risque lié à la sécurité de l’information |
| [3] | **ISO 31000:2018** | Principes et lignes directrices pour le management du risque |
| [4] | **CIS Controls v8** | Contrôles techniques et opérationnels pour la réduction du risque |
| [5] | **Microsoft EAM** | Segmentation et gestion du risque par tiering |
| [6] | **ISO/IEC 27001:2022** | Contexte global de la sécurité et des risques |
| [7] | **ITIL v4** | Gestion des changements et du risque opérationnel |
