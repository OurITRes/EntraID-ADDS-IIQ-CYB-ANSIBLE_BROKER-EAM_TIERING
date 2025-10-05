# SECURITY

## 1. Objectif et périmètre de sécurité

Ce document décrit la posture de sécurité opérationnelle de la solution **EntraID-ADDS-IIQ-CYB-ANSIBLE_BROKER-EAM_TIERING_v1.0**.  
Il s’applique à l’ensemble des composants identitaires et d’administration privilégiée, couvrant les environnements **DEV**, **TST** et **PRD**, selon le modèle de tiering Microsoft **EAM** (T0, T1, T2).

Les objectifs principaux sont :
- Garantir l’intégrité et la confidentialité des identités.
- Supprimer tout accès permanent (“standing access”) au profit du **Just-In-Time**.
- Assurer la traçabilité complète des actions.
- Aligner la sécurité technique sur les cadres **NIST SP 800-53 rev5**, **CIS Controls v8**, **ISO/IEC 27001:2022**, et **NIST CSF 2.0** [1]–[7].

---

## 2. Modèle Zero Trust appliqué à l’écosystème EntraID–ADDS–IIQ–CyberArk

Le principe Zero Trust repose sur trois piliers appliqués ici :

| Pilier | Application dans la solution |
|--------|-------------------------------|
| **Ne jamais faire confiance par défaut** | Tous les accès sont soumis à PIM ou CyberArk JIT. Aucun compte n’est permanent. |
| **Vérifier systématiquement** | MFA obligatoire sur tous les portails administratifs. Authentification basée sur contexte (device compliant, localisation, risk score). |
| **Réduire les surfaces et les privilèges** | Segmentation T0–T1–T2, isolation des PAW, JEA endpoints et rôles à portée limitée. |

Le modèle Zero Trust est implémenté transversalement :
- **Identité** : Entra ID et IIQ forment la racine de confiance.  
- **Accès** : PIM et CyberArk garantissent le JIT.  
- **Appareil** : seuls les PAW conformes (MDM/Intune) sont autorisés.  
- **Applications** : CA restreint les accès aux portails sensibles.  
- **Réseau** : segmentation par zone et par tier.  
- **Télémétrie** : logs centralisés vers Splunk / Grafana.

---

## 3. Durcissement (Hardening)

### 3.1 Active Directory Domain Services (ADDS)
- Désactivation de NTLMv1, LM, SMBv1, LDAP non chiffré.  
- Mise en œuvre de **LSASS PPL**, **Credential Guard** et **Protected Users**.  
- GPOs durs : verrouillage des comptes, audit success/failure, LAPS activé.  
- Service accounts remplacés par **gMSA**, isolés par OU et FGPP.  
- Contrôle d’intégrité AD : Quest Change Auditor + RMAD DRE.  
- Séparation stricte des comptes administratifs (AGDLP / AdminSDHolder).  
- SIDHistory bloqué et filtrage des trusts inter-forêts.

### 3.2 Entra ID / PIM / Conditional Access
- Rôles cloud configurés en **eligible-only**.  
- MFA + device compliance pour tout accès aux portails Entra / Azure / M365.  
- Session Control via Defender for Cloud Apps : blocage de téléchargement et watermark.  
- Limitation des *Administrative Units* à leur périmètre environnement / tier.  
- Logging activé pour toutes les opérations PIM et Connect Sync.

### 3.3 CyberArk PVWA / PSM
- Accès via **HTTPS (443)** avec authentification SAML + Entra ID.  
- Rôles CyberArk alignés sur le tier EAM.  
- Secrets stockés dans des **Safe** dédiés T0/T1/T2.  
- PSM Proxy activé, enregistrement vidéo des sessions.  
- Rotation immédiate post-session.  
- Audit des logs via Splunk index `cyberark_sessions`.

### 3.4 PAW (Privileged Access Workstations)
- Images gold gérées par Intune / Autopilot.  
- **WDAC**, **ASR**, **BitLocker**, **PPL**, **Tamper Protection** activés.  
- Authentification uniquement avec comptes T1/T0 via PIM.  
- Aucune navigation Internet directe.  
- Journaux envoyés au SIEM.

---

## 4. Contrôles et conformité

### 4.1 Contrôles NIST SP 800-53 rev5
| Contrôle | Description | Implémentation |
|-----------|--------------|----------------|
| AC-2 | Account Management | IIQ LCM + Workflow de désactivation automatique |
| AC-6 | Least Privilege | JEA / PIM / JIT CyberArk |
| IA-2 | Identification and Authentication | MFA, CA, device compliance |
| AU-12 | Audit Generation | Splunk, Grafana, PSM transcripts |
| CM-6 | Configuration Settings | GPO durcies, Terraform baselines |

### 4.2 Mapping des contrôles et outils de vérification
| Contrôle | Norme | Outil / Vérification | Fréquence |
|-----------|--------|----------------------|------------|
| AC-2 | NIST SP 800-53 | IIQ certification campaign | Mensuel |
| IA-2 | NIST SP 800-53 | Entra ID PIM / MFA logs | Quotidien |
| AU-12 | NIST SP 800-53 | Splunk dashboard `audit_trace` | Temps réel |
| CM-6 | NIST SP 800-53 | Ansible compliance playbooks | Hebdomadaire |
| CIS 5.2 | CIS Controls v8 | Quest GPOAdmin / RMAD DRE | Mensuel |
| ISO 27001 A.9.4.1 | ISO/IEC 27001 | Audit interne / SOC | Trimestriel |

---

## 5. Segmentation réseau & défense en profondeur

La segmentation repose sur trois zones administratives (T0/T1/T2) et des bastions isolés.  
Les flux autorisés sont strictement définis (WinRM, RDP, HTTPS).

**Modèle de défense en profondeur :**

```
                +-------------------------------+
                |        Users / T2 (PRD)       |
                |  MFA, CA, Device compliance   |
                +---------------+---------------+
                                |
                                v
                +-------------------------------+
                |        Admins / T1 (Ops)       |
                |   PAW, PIM, JEA, PVWA/PSM      |
                +---------------+---------------+
                                |
                                v
                +-------------------------------+
                |       Core / T0 (Identity)     |
                |  CyberArk Vault, DC, IIQ, PIM  |
                +---------------+---------------+
                                |
                                v
                +-------------------------------+
                |       Monitoring & SIEM        |
                |     Splunk, Grafana, Alerts    |
                +-------------------------------+
```

Chaque couche est indépendante et surveillée.  
Les transitions inter-tiers nécessitent un **bastion PSM** et une **authentification MFA**.

---

## 6. Gestion des privilèges (PIM / JIT / JEA / PVWA)

La gestion des privilèges suit le cycle **Demande → Validation → Session → Clôture → Audit**.

1. **IIQ** reçoit la demande (T0 ou T1).  
2. **Workflow** d’approbation (IAM + SecOps).  
3. **CyberArk PVWA** déclenche la session JIT.  
4. **PSM** isole et enregistre la session.  
5. **JEA endpoint** restreint les commandes.  
6. **Rotation du secret** et **upload des logs** vers Splunk.

Les rôles Entra ID PIM sont en mode *eligible-only*, avec durée et justification contrôlées.

---

## 7. Protection des secrets et clés

- Tous les secrets d’API, tokens et certificats sont stockés dans **CyberArk** ou **Azure Key Vault**.  
- Les clés Terraform et Ansible sont récupérées dynamiquement via OIDC.  
- Aucun secret n’est présent dans les pipelines GitHub.  
- **KMS AWS / Azure Key Vault** assurent le chiffrement des volumes ADDS, PSM et Connect.

---

## 8. Journalisation, SIEM et corrélation

Toutes les activités critiques sont centralisées dans Splunk.

| Source | Type d’événement | Détail | Fréquence |
|---------|------------------|--------|-----------|
| Entra ID / PIM | Activation, MFA, CA | `entra_pim.log` | Temps réel |
| IIQ | Workflow, approbations | `iiq_lcm.log` | 5 min |
| CyberArk PVWA / PSM | Accès JIT, session | `cyberark_sessions.log` | Temps réel |
| ADDS | Audit Policy, Kerberos | `adds_security.evtx` | Continu |
| Ansible / GitHub Actions | CI/CD | `pipeline.log` | A chaque run |

Les tableaux de bord corrèlent les activations JIT, les sessions PSM et les approbations IIQ.  
Les alertes critiques sont transmises au SOC (MS Teams / PagerDuty).

---

## 9. Menaces et Mitigation (MITRE ATT&CK + matrice EAM Tier)

### 9.1 Risques principaux par Tier

| Tier | Risque principal | Technique MITRE | Mitigation | Contrôle associé |
|------|------------------|------------------|-------------|------------------|
| **T0** | Credential Dumping (LSASS) | T1003 | LSASS PPL + isolation PSM + rotation immédiate | NIST AC-6 / CIS 6.8 |
| **T1** | Privilege Escalation (OS exploit) | T1068 | JEA restriction + segmentation réseau + WDAC | NIST CM-6 / CIS 4.3 |
| **T2** | Phishing / Lateral Movement | T1566 / T1021 | MFA, CA, isolation comptes standards | NIST IA-2 / CIS 1.6 |

### 9.2 Risques transversaux

| Catégorie | Menace | Mitigation |
|------------|----------|-------------|
| Synchronisation | Compromission du connecteur Entra Connect | Comptes gérés T0, durcissement TLS, logs d’audit |
| API | Token reuse / exfiltration | OIDC + rotation des tokens + scan secrets | 
| Automatisation | Playbook altéré | Signatures GPG + contrôle de checksum | 
| Bastions | Exploitation RDP | PSM enforced + network ACL strictes |
| Données | Shadow IT | IIQ recertification + DLP Defender |

---

## 10. Bonnes pratiques et recommandations durables

- Segmenter physiquement les réseaux d’administration.  
- Interdire toute authentification interactive sur T0.  
- Activer les **baselines Defender for Identity** et **Attack Surface Reduction**.  
- Vérifier mensuellement la conformité via **PingCastle** et **Quest Security Guardian**.  
- Centraliser tous les artefacts IaC, GPO et CA dans un dépôt Git versionné.  
- Tester régulièrement les procédures **break-glass** documentées dans `runbooks/`.

---

## 11. Annexes techniques

### 11.1 Exemples de configuration
**GPO (Durcissement DC)**
```ini
[System\CurrentControlSet\Control\Lsa]
RunAsPPL=1
AuditBaseObjects=1
```

**Conditional Access (JSON)**
```json
{
  "displayName": "CA-PIM-Activation-PAW-Only",
  "grantControls": {
    "builtInControls": ["mfa", "compliantDevice"]
  }
}
```

**JEA Endpoint (PowerShell)**
```powershell
RoleDefinitions = @{
  'DOMAIN\JEA-T0-Operators' = @{ RoleCapabilities = 'JEA.AD.T0' }
}
```

---

## Références normatives

| Réf. | Norme / Cadre | Description |
|------|----------------|-------------|
| [1] | **NIST SP 800-207** | Zero Trust Architecture |
| [2] | **Microsoft EAM** | Tiering T0–T2 et séparation fonctionnelle |
| [3] | **NIST SP 800-53 rev5** | Contrôles AC, IA, AU, CM |
| [4] | **CIS Controls v8** | Sécurité AD et durcissement systèmes |
| [5] | **MITRE ATT&CK** | Catalogue de tactiques et techniques adverses |
| [6] | **ISO/IEC 27001:2022** | SGSI et exigences de certification |
| [7] | **NIST CSF 2.0** | Identify / Protect / Detect / Respond / Recover |
