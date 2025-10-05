# IMPLEMENTATION

## 1. Introduction

Ce document décrit la **mise en œuvre technique complète** de la plateforme **EntraID-ADDS-IIQ-CYB-ANSIBLE_BROKER-EAM_TIERING_v1.0**.  
Il sert à la fois de **manuel d’intégration** et de **plan de déploiement multi-environnements**.

La solution combine :
- **SailPoint IIQ** pour la gouvernance des identités,  
- **Entra ID** comme pivot cloud (PIM, CA, AUs),  
- **CyberArk PVWA/PSM** pour le Just-In-Time (JIT),  
- **Ansible / GitHub Actions** comme orchestrateur,  
- et **Active Directory Domain Services** (ADDS) multi-forêts sécurisées selon le modèle **EAM** (T0, T1, T2).  

Chaque étape est automatisée, versionnée et auditable.  
Les contrôles normatifs appliqués reposent sur **NIST SP 800-53 rev5**, **CIS Controls v8**, **ISO 27001:2022** et le **NIST CSF 2.0** [1]–[7].

---

## 2. Préparation des environnements (DEV, TST, PRD)

Le déploiement se fait en quatre phases progressives :  

| Phase | Description | Environnements concernés | Objectif | Avancement estimé | Livrables principaux |
|-------|--------------|---------------------------|-----------|--------------------|-----------------------|
| **1** | Infrastructure-as-Code (Terraform) | DEV, TST, PRD | Déploiement des fondations identitaires | 100 % | `providers.tf`, `main.tf`, `modules/`, `outputs.tf` |
| **2** | Intégration IIQ / Orchestrateur / Entra ID | DEV, TST | Connecteurs SCIM / Graph API / Ansible | 80 % | `integration/`, `playbooks/`, `iiq_scim_mapping.csv` |
| **3** | Sécurité (CyberArk, PIM, CA, JEA, PAW) | TST, PRD | Contrôles JIT, isolation, bastions | 60 % | `policies/`, `runbooks/`, `jea_mechanics.puml` |
| **4** | Observabilité & Gouvernance | PRD | Supervision, alerting, KPI | 40 % | `observability/`, `dashboard_kpis.json`, `grafana/` |

Chaque phase est réalisée d’abord en **DEV**, puis répliquée et validée en **TST**, avant promotion vers **PRD** via pipeline CI/CD GitHub.

---

## 3. Infrastructure-as-Code (Terraform)

Le code Terraform est contenu dans le dossier `/terraform/`.  
Il définit les **providers**, **groupes dynamiques Entra**, **politiques PIM**, et **Administrative Units**.

**Exemple : `providers.tf`**
```hcl
terraform {
  required_providers {
    azuread = { source = "hashicorp/azuread", version = "~> 3.0" }
    microsoft365 = { source = "hashicorp/microsoft365", version = "~> 0.1" }
  }
  backend "azurerm" {
    resource_group_name  = "rg-iac-state"
    storage_account_name = "stadiacstate"
    container_name       = "tfstate"
    key                  = "entra_id_state.tfstate"
  }
}
```

**Exemple : `dynamic_groups.tf`**
```hcl
resource "azuread_group" "dynamic_t2_prd" {
  display_name     = "ENTRA-T2-PRD"
  security_enabled = true
  mail_enabled     = false
  membership_rule  = "(user.extensionAttribute10 -eq \"T2\") and (user.extensionAttribute11 -eq \"PRD\")"
  membership_rule_processing_state = "On"
}
```

**Outputs :**
```hcl
output "entra_group_t2_prd_id" {
  value = azuread_group.dynamic_t2_prd.id
}
```

Chaque commit Terraform déclenche un **plan** automatique dans GitHub Actions (job `terraform-plan`), puis un `apply` après validation manuelle.  
Les secrets (SPN, tenant, subscription) sont gérés via **OIDC GitHub ↔ Azure**.

---

## 4. Orchestrateur (GitHub Actions / Ansible)

Le rôle de l’orchestrateur est d’exécuter les workflows d’intégration et d’automatisation.  
Les **runners self-hosted T1** opèrent dans un réseau d’administration isolé.  

**Workflow principal : `update-entra-extensionattributes.yml`**
```yaml
name: Update Entra extensionAttributes
on:
  workflow_dispatch:
jobs:
  patch-graph:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.GRAPH_APP_ID }}
          tenant-id: ${{ secrets.GRAPH_TENANT_ID }}
          allow-no-subscriptions: true
      - name: PATCH Graph
        run: |
          az rest --method PATCH             --uri "https://graph.microsoft.com/v1.0/users/${{ inputs.user_upn }}"             --headers "Content-Type=application/json"             --body '{ "extensionAttribute10":"T2","extensionAttribute11":"PRD","extensionAttribute12":"Standard"}'
```

Les **playbooks Ansible** sous `/playbooks/` automatisent :
- le provisioning T2 standard (`playbooks/t2_user_provision.yml`),
- le déclenchement de sessions JIT via CyberArk (`playbooks/t1_admin/grant_t1_jit_pvwa_api.yml`),
- la création d’unités administratives Entra (`playbooks/entra_au_create.yml`).

**Exemple :**
```yaml
- name: Request JIT via PVWA
  uri:
    url: "{{ pvwa_base_url }}/PasswordVault/API/Accounts/{{ account_id }}/Requests"
    method: POST
    headers:
      Authorization: "Bearer {{ pvwa_token }}"
      Content-Type: "application/json"
    body:
      durationMinutes: 60
      reason: "JIT via IIQ workflow"
```

---

## 5. Workflows SailPoint IIQ

IIQ agit comme **moteur d’orchestration de gouvernance**.  
Les workflows sont développés en **Beanshell / XML** et déclenchent les webhooks Ansible via API REST.

### Provisioning T2
- Création du compte dans **ADDS-PRD**.  
- Affectation des groupes métier (AGDLP).  
- Synchronisation vers Entra ID via Connect.  
- Mise à jour de `extensionAttribute10..13` par API Graph.

### Demande d’accès T1
- Workflow “Privileged Access Request”.  
- Approbation IAM + contrôle de justification.  
- Appel de l’orchestrateur (webhook HTTPS signé HMAC).  
- Déclenchement du playbook CyberArk (JIT) et création temporaire du rôle PIM.

**Extrait XML simplifié**
```xml
<Workflow name="RequestPrivilegedAccessT1">
  <Step name="CollectInput" next="Approval"/>
  <Step name="Approval" next="CallWebhook"/>
  <Step name="CallWebhook">
    <Action class="InvokeRESTAction">
      <url>https://ansible-runner/api/jit/t1</url>
      <method>POST</method>
      <headers>{"Authorization":"HMAC {{sig}}"}</headers>
      <body>{"user":"${identity}","tier":"T1"}</body>
    </Action>
  </Step>
</Workflow>
```

---

## 6. Intégration CyberArk PVWA / PSM

CyberArk est le **pivot de l’accès Just-In-Time**.  
Les modules configurés :
- **PVWA API** pour les requêtes d’accès,
- **PSM** pour l’enregistrement des sessions,
- **PTA** (Threat Analytics) pour la détection des anomalies.

### API call typique
```http
POST /PasswordVault/API/Accounts/{id}/Requests
Authorization: Bearer {{token}}
Content-Type: application/json

{
  "Reason": "JIT via IIQ",
  "DurationMinutes": 60
}
```

### Fin de session
Lors de la clôture :
- Le **check-in** du secret s’effectue automatiquement.  
- La **rotation** est immédiate.  
- Les logs PSM sont transmis à Splunk (`observability/splunk/inputs_psm.conf`).  

---

## 7. Intégration Entra ID (PIM, CA, Defender, AUs)

La couche Entra ID est le **cœur cloud du modèle d’identité**.

### PIM
- Tous les rôles sont en **eligible-only**.  
- Durées : T1 = 120 min, T0 = 60 min.  
- Approbations requises et MFA obligatoire.

### Conditional Access
- Policies JSON : `policies/conditional-access/CA-PIM-Activation-PAW-Only.json`.  
- MFA + device compliant + PAW enforced.  
- Defender for Cloud Apps : `policies/defender-for-cloud-apps/MDA-Admin-Portals-Restrict-Downloads.json`.

### Administrative Units
- Fichiers JSON : `entra/administrative-units/AU-PRD-T0.json`, `AU-DEV-T1.json`, `AU-TST-T2.json`.  
- Délégations par environnement et par tier.

---

## 8. Observabilité et supervision

Les journaux sont collectés par **Splunk** et visualisés dans **Grafana**.

| Source | Description | Destination |
|---------|--------------|--------------|
| PVWA/PSM | Sessions JIT et enregistrements vidéo | index `cyberark_sessions` |
| Ansible / GitHub Actions | Logs de provisioning | index `automation_ci` |
| Entra ID / PIM | Activations de rôles | index `entra_pim` |
| IIQ | Recertifications / approvals | index `iiq_governance` |

**Dashboard Splunk** : `observability/splunk/dashboard_identity_jit.xml.json`  
**Grafana KPIs** : `observability/grafana/dashboard_kpis.json`

---

## 9. Sécurité d’exécution (PAW, JEA, segmentation)

Chaque commande d’administration est exécutée depuis un **poste PAW** selon le **tier**.  
Les commandes PowerShell sont limitées par **JEA endpoints** et **RoleCapabilities**.

**Exemple JEA T1 :**
```powershell
@{
  SchemaVersion = '2.0.0.0'
  SessionType   = 'RestrictedRemoteServer'
  TranscriptDirectory = 'C:\JEA\Transcripts\T1'
  RoleDefinitions = @{
    'DOMAIN\JEA-T1-Operators' = @{ RoleCapabilities = 'JEA.AD.T1' }
  }
}
```

**Flux réseau autorisés :**
- HTTPS 443 → PVWA / Entra ID / API Graph  
- WinRM 5985-5986 → JEA endpoints  
- RDP proxifié → PSM bastions  

Toutes les sessions sont isolées et traçables [2][3].

---

## 10. Bonnes pratiques d’implémentation

- **Aucune élévation directe** entre Tiers.  
- **Runners isolés** par environnement et rôle.  
- **Tags IaC normalisés** (`Tier`, `Env`, `Owner`, `Criticality`).  
- **Audit continu** : IIQ → PIM → CyberArk → SIEM.  
- **Durcissement PAW** : WDAC, ASR, LSA PPL, BitLocker.  
- **Documentation vivante** : chaque modification de pipeline ou playbook génère un changelog Markdown (`CHANGELOG.md`).

---

## 11. Annexes techniques

### 11.1 Extraits Terraform
`terraform/modules/entra_dynamic_group/main.tf`
```hcl
resource "azuread_group" "entra_dynamic_group" {
  display_name = var.display_name
  membership_rule = "(user.extensionAttribute10 -eq \"${var.tier}\") and (user.extensionAttribute11 -eq \"${var.env}\")"
}
```

### 11.2 Extraits Ansible
`playbooks/t1_admin/grant_t1_jit_pvwa_api.yml`
```yaml
- name: Grant T1 JIT Access via PVWA
  uri:
    url: "{{ pvwa_base_url }}/PasswordVault/API/Accounts/{{ account_id }}/Requests"
    method: POST
    headers:
      Authorization: "Bearer {{ pvwa_token }}"
    body:
      durationMinutes: 60
      reason: "JIT via IIQ"
```

### 11.3 Pipeline CI/CD complet
`github/workflows/full_pipeline.yml`
```yaml
name: CI/CD Identity Platform
on: [push]
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init && terraform apply -auto-approve
  ansible:
    runs-on: self-hosted
    needs: terraform
    steps:
      - uses: actions/checkout@v4
      - name: Provision ADDS Accounts
        run: ansible-playbook playbooks/t2_user_provision.yml
  iiq-integration:
    runs-on: ubuntu-latest
    needs: ansible
    steps:
      - name: Notify IIQ via API
        run: |
          curl -X POST https://iiq/api/v1/notify           -H "Authorization: Bearer ${{ secrets.IIQ_TOKEN }}"           -d '{"status":"completed"}'
```

---

## Références normatives

| Réf. | Norme / Cadre | Description |
|------|----------------|-------------|
| [1] | **NIST SP 800-207** | Zero Trust Architecture |
| [2] | **Microsoft EAM** | Tiering T0–T2 |
| [3] | **NIST SP 800-53 rev5** | Contrôles AC / IA / AU |
| [4] | **CIS Controls v8** | Sécurité Active Directory |
| [5] | **MITRE ATT&CK** | Techniques d’escalade et persistance |
| [6] | **ISO/IEC 27001:2022** | SGSI |
| [7] | **NIST CSF 2.0** | Identify / Protect / Detect / Respond / Recover |
