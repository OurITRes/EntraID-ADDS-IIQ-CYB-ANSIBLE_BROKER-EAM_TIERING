# OPERATIONS

## 1. Objectif et périmètre d’exploitation

Ce document définit les principes, les procédures et les mécanismes d’exploitation de la plateforme **EntraID–ADDS–IIQ–CyberArk–Ansible**, intégrée selon le modèle de sécurité **EAM Tiering (T0–T1–T2)**.

L’objectif est de garantir :
- la **disponibilité continue** des services identitaires,  
- la **cohérence** entre les environnements (DEV, TST, PRD),  
- la **traçabilité** des opérations,  
- la **réactivité** en cas d’incident ou de failover,  
- et la **conformité** vis-à-vis des cadres NIST CSF 2.0, ISO 20000 et ITIL v4.

---

## 2. Gouvernance opérationnelle et rôles

Les opérations quotidiennes sont assurées par plusieurs équipes coordonnées selon le modèle **RACI** suivant.

| Activité | IIQ | CyberArk | Entra ID | ADDS | SOC | GRC |
|-----------|-----|-----------|----------|------|-----|-----|
| Provisioning utilisateurs | **R** | C | I | I | - | - |
| Activation JIT / PIM | I | **R** | **C** | I | - | - |
| Revue des accès | **R** | C | I | I | - | **A** |
| Surveillance des logs | - | I | I | I | **R** | **C** |
| Gestion des incidents | C | C | C | C | **R** | **A** |
| Maintenance ADDS | I | I | **C** | **R** | I | - |
| Gestion des patchs | - | - | - | **R** | **C** | **A** |
| Conformité et audit | C | C | C | C | I | **R** |

Légende : **R = Responsible**, **A = Accountable**, **C = Consulted**, **I = Informed**

Chaque équipe agit dans les limites de son **tier EAM** :
- **T0** : infrastructure critique (DC, CyberArk, IIQ)  
- **T1** : exploitation (AD, Entra, automations)  
- **T2** : utilisateurs et environnements métiers  

---

## 3. Supervision et alerting

### 3.1 Sources d’événements
Les journaux sont collectés via Splunk, Grafana et Defender for Cloud Apps.  
Les principales sources sont :

| Source | Type d’événement | Détail |
|---------|------------------|--------|
| Entra ID / PIM | Activations, MFA, CA | Audit role activation, conditional policies |
| IIQ | Workflows, approbations, recertifications | LCM, Request, Certifications |
| CyberArk PVWA / PSM | Sessions JIT, rotation, anomalies | Safe logs, session transcripts |
| ADDS | Sécurité, Kerberos, LSASS | Windows EventID 4624, 4625, 4740 |
| Ansible / GitHub Actions | CI/CD pipelines | Provisioning logs, IaC deployment |
| PAW | Sécurité locale, durcissement | WDAC logs, Defender events |

---

### 3.2 Critical Event Matrix

| Événement | Source | Seuil | Action automatique | Escalade |
|------------|---------|--------|--------------------|-----------|
| Échec MFA répété | Entra ID | >3 en 5 min | Blocage CA + alerte SOC | Niveau 2 |
| Session PSM non clôturée | CyberArk | >1h | Rotation forcée | Niveau 1 |
| Compte désactivé réactivé | ADDS | 1 fois | Notification IIQ + audit | Niveau 2 |
| Anomalie JIT prolongée | PVWA | >60 min | Revocation token | Niveau 2 |
| Token API expiré | Orchestrateur | Événement | Regénération via OIDC | Niveau 3 |
| DC en échec de réplication | ADDS | 1 instance | Alerte PagerDuty | Niveau 1 |
| Volume Key Vault saturé | Azure Monitor | >80% | Rotation et purge | Niveau 2 |

---

### 3.3 Automatisation des alertes

- Les alertes critiques (niveau 1–2) génèrent un ticket dans le système ITSM (ServiceNow).  
- Les alertes de niveau 3 sont traitées par l’équipe IAM.  
- Les actions automatisées sont orchestrées via **Ansible Tower** ou **GitHub Actions** selon l’environnement.

---

## 4. Maintenance préventive et corrective

### 4.1 Tâches récurrentes

| Fréquence | Tâche | Responsable |
|------------|--------|-------------|
| Quotidien | Vérification réplication ADDS | AD Ops |
| Quotidien | Analyse logs PSM / PIM | SOC |
| Hebdomadaire | Validation des jobs Ansible | Infra Ops |
| Hebdomadaire | Vérification LCM IIQ / désactivation comptes inactifs | IAM |
| Mensuel | Campagne de recertification des accès | IIQ |
| Mensuel | Rapport conformité CIS / PingCastle | GRC |
| Trimestriel | Test PRA et bascule DC | Infra + SOC |

---

### 4.2 Gestion des patchs et mises à jour
- Les DC sont patchés selon un **cycle mensuel contrôlé** (WSUS / Ansible).  
- Les PAW suivent les **Windows Servicing Channels** (Enterprise LTSC).  
- Les mises à jour CyberArk et IIQ sont testées en TST avant déploiement en PRD.

---

### 4.3 Gestion des incidents
- Les incidents sont classifiés en 3 niveaux :  
  - **P1** : impact global ou sécurité critique (SOC lead).  
  - **P2** : défaillance partielle ou dégradation (Ops lead).  
  - **P3** : anomalie mineure (IAM ou Support N2).  
- Les rapports post-mortem sont produits sous 48 h dans `/incidents/`.

---

## 5. Résilience et continuité d’activité

### 5.1 Sauvegarde et restauration
- Sauvegardes quotidiennes des DC via VSS + snapshots AWS/Azure.  
- Vaults CyberArk répliqués en mode DR asynchrone.  
- Backups IIQ exportés sous format XML + DB dump.  
- Entra ID : récupération via **Soft Delete** et **Recycle Bin** pour groupes et utilisateurs.

### 5.2 Plan de reprise d’activité (PRA)
- RPO = 1 h, RTO = 4 h pour ADDS et CyberArk.  
- PRA testé trimestriellement avec restauration complète du DC primaire.  
- Documentation PRA stockée dans `/runbooks/PRA_ADDS_CYB.md`.

### 5.3 Tests de bascule
- Réalisés sur environnement TST avec scripts Terraform “failover ready”.  
- Résultats consignés dans Grafana via métriques “PRA Success Rate”.

---

## 6. SOC et gestion des événements de sécurité

### 6.1 Intégration SIEM (Splunk, Grafana)
- Ingestion temps réel depuis :
  - Entra ID / PIM (API Graph),
  - CyberArk (PSM, PVWA),
  - ADDS Event Logs,
  - IIQ (approvals),
  - Orchestrateur (actions Ansible / GitHub).

**Exemple de requête Splunk :**
```spl
index=cyberark_sessions OR index=entra_pim
| stats count by user, source, result
| where result="failure"
```

### 6.2 Playbooks de réponse aux incidents
- Playbooks Ansible déclenchés automatiquement pour :
  - Révocation d’accès JIT,
  - Rotation de secrets compromis,
  - Désactivation de comptes suspects,
  - Notification MS Teams SecOps.

### 6.3 Reporting et métriques SOC
| Indicateur | Objectif | Fréquence |
|-------------|-----------|------------|
| MTTD (Mean Time To Detect) | < 15 min | Hebdomadaire |
| MTTR (Mean Time To Respond) | < 60 min | Hebdomadaire |
| % d’incidents auto-résolus | > 70 % | Mensuel |
| % de comptes MFA conformes | 100 % | Temps réel |

---

## 7. Automatisation opérationnelle

- **Ansible** gère la maintenance ADDS, la vérification de réplication, la désactivation de comptes inactifs et la rotation des mots de passe.  
- **GitHub Actions** automatise les workflows IaC (Terraform / Entra ID).  
- **IIQ** orchestre les workflows LCM et JIT.  

**Exemple Ansible :**
```yaml
- name: Audit des DC et réplication
  win_command: repadmin /replsummary
  register: result
  changed_when: false
  failed_when: "'fails' in result.stdout"
```

---

## 8. Indicateurs de performance (KPI / SLO / SLA)

| Indicateur | Description | Seuil / Objectif | Source |
|-------------|-------------|------------------|--------|
| MTTD | Temps moyen de détection | < 15 min | SOC dashboards |
| MTTR | Temps moyen de résolution | < 60 min | ITSM / SOC |
| Disponibilité ADDS | % uptime mensuel | > 99,9 % | Grafana |
| Disponibilité CyberArk | % uptime mensuel | > 99,7 % | PVWA logs |
| Couverture de logs SIEM | % événements corrélés | > 95 % | Splunk |
| Conformité MFA | Comptes MFA actifs | 100 % | Entra ID |
| Recertifications complètes | % utilisateurs revus | > 98 % | IIQ |

---

## 9. Bonnes pratiques d’exploitation

- Appliquer le **principe du moindre privilège** à tous les outils d’exploitation.  
- Mettre à jour les **playbooks et pipelines** à chaque changement majeur.  
- Réaliser des **exercices PRA et break-glass** tous les trimestres.  
- Documenter chaque incident dans `/incidents/` avec cause racine.  
- Vérifier la conformité des PAW avant chaque cycle d’administration.  
- Maintenir les scripts d’automatisation sous contrôle Git avec validation par pairs.

---

## 10. Annexes techniques

### 10.1 Exemple de runbook : Breakglass T0
`runbooks/RUNBOOK_BREAKGLASS_T0.yml`
```yaml
- name: Activation du compte Breakglass T0
  hosts: localhost
  gather_facts: no
  vars:
    breakglass_user: "T0-BREAKGLASS"
  tasks:
    - name: Vérifier disponibilité du DC primaire
      win_ping:
      register: ping_result
      failed_when: ping_result.ping is not defined

    - name: Activer le compte Breakglass T0
      win_user:
        name: "{{ breakglass_user }}"
        state: present
        enabled: yes
        password: "{{ lookup('env','BREAKGLASS_PWD') }}"
      when: ping_result.ping == 'pong'

    - name: Notifier SOC de l’activation
      uri:
        url: "https://soc-api.local/incident"
        method: POST
        body: '{"user":"{{ breakglass_user }}","action":"activated"}'
        headers:
          Content-Type: "application/json"

    - name: Rotation du mot de passe après usage
      win_user:
        name: "{{ breakglass_user }}"
        password: "{{ lookup('passwordstore','breakglass/rotate') }}"
```

---

## Références normatives

| Réf. | Norme / Cadre | Description |
|------|----------------|-------------|
| [1] | **NIST CSF 2.0** | Identify / Protect / Detect / Respond / Recover |
| [2] | **ISO/IEC 20000** | Gestion des services informatiques |
| [3] | **ITIL v4** | Opérations, Incident & Problem Management |
| [4] | **NIST SP 800-61r2** | Computer Security Incident Handling Guide |
| [5] | **CIS Controls v8** | Contrôles opérationnels et supervision |
| [6] | **Microsoft EAM** | Tiering et gouvernance des opérations |
| [7] | **ISO 22301** | Continuité et résilience des activités |
