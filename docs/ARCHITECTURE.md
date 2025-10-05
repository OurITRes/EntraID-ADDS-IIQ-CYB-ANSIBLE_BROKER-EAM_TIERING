# ARCHITECTURE

## 1. Objectif et périmètre

### 1.1 Objectif
Ce document décrit l’**architecture cible** de la solution **EntraID-ADDS-IIQ-CYB-ANSIBLE_BROKER-EAM_TIERING_v1.0** :  
- **gouvernance des identités** centralisée par **SailPoint IIQ** ;  
- **pivot cloud** via **Microsoft Entra ID** (PIM, CA, AUs) ;  
- **accès privilégié JIT** via **CyberArk PVWA/PSM** ;  
- **orchestration** par **Ansible/GitHub Actions** ;  
- **annuaire(s) ADDS multi-forêts** ;  
- **tiering EAM** (T0/T1/T2) et **Zero Trust** [1][2][3].

### 1.2 Périmètre
- **Flux T2 standard** : provisioning et licence (une licence par personne) ;  
- **Flux T1 & T0 privilégiés** : demandes d’accès JIT, sessions via PAW, PIM, PVWA, PSM, JEA ;  
- **Données d’identité** : mapping IIQ ↔ Entra ID (extensionAttributes) ;  
- **Sécurité** : PIM, CA, JEA, PAW, segmentation réseau ;  
- **Automatisation** : workflows IIQ, Ansible, GitHub Actions, Terraform ;  
- **Observabilité** : Splunk / Grafana (corrélation e2e).  

**Hors périmètre** : MDM, gestion applicative non-identitaire, migrations applicatives.

---

## 2. Vues d’architecture

### 2.1 Vue logique (acteurs & composants)
- **Acteurs** :  
  - *User T2* (employé) ; *Admin T1/T0* (éligible PIM, pas d’accès permanent).  
  - *Approvers* (IIQ, IAM, SecOps).  
- **Composants** :  
  1) **SailPoint IIQ** (LCM, approbations, recertifications).  
  2) **Orchestrateur** (GitHub Actions + Ansible runner T1).  
  3) **CyberArk** (PVWA, PSM, rotation).  
  4) **Entra ID** (AUs, PIM, CA, SCIM/Graph).  
  5) **AD DS** (multi-forêts, OU déléguées, JEA endpoints).  
  6) **PAW T1/T0** (postes dédiés).  
  7) **SIEM/Observabilité** (Splunk, Grafana).

> Réf. diagramme C4 (conteneurs) : `diagrams/c4_highlevel.puml`.

### 2.2 Vue fonctionnelle (flux clés)
- **Flux T2** : IIQ → Orchestrateur → AD DS (PRD) → Entra Connect → Entra ID → Licence → Groupes dynamiques → CA/PIM.  
- **Flux T1 JIT** : IIQ (demande) → Orchestrateur (webhook) → PVWA (JIT) → PSM (session) → Bastion JEA T1 → (Group JIT si nécessaire) → clôture/rotation.  
- **Flux T0 JIT** : IIQ (double approbation) → PVWA (JIT) → PSM (session T0) → Bastion JEA T0 → clôture/rotation stricte.

> Réf. séquences : `diagrams/tier2_provisioning.puml`, `diagrams/tier1_admin_access.puml`, `diagrams/tier0_admin_access.puml`, `diagrams/jea_mechanics.puml`.

### 2.3 Vue physique (zones & frontières de confiance)
- **Zones** :  
  - *User LAN* (T2), *Admin LAN* (PAW T1/T0) ;  
  - *Bastions* (MGMT-T1/T0) ;  
  - *Core Identity* (Entra ID, IIQ, CyberArk PVWA/PSM) ;  
  - *AD DS* (forêts PRD / DEV / TST).  
- **Frontières** :  
  - Accès portails Entra/CyberArk **via CA** (MFA + PAW-only) ;  
  - Sessions privilegiées **via PSM** ;  
  - Commandes admin **via JEA** ;  
  - Synchronisation AD→Entra **via Connect** ;  
  - API Graph **via Service Principal restreint**.  

---

## 3. Modèle de données identité & attributs

### 3.1 Attributs Entra ID (extensionAttributes)
| Attribut | Rôle | Valeurs typiques | Source |
|---|---|---|---|
| `extensionAttribute10` | **Tier** | `T0` / `T1` / `T2` | IIQ/Orchestrateur |
| `extensionAttribute11` | **Environnement** | `PRD` / `DEV` / `TST` / `SBX` | IIQ/Orchestrateur |
| `extensionAttribute12` | **Type de compte** | `Standard` / `Admin` / `Service` | IIQ/Orchestrateur |
| `extensionAttribute13` | **Cost Center** | `FIN001` (normalisé) | IIQ/HR |

Ces champs alimentent :
- **Groupes dynamiques** Entra ID (règles sur `extensionAttributeX`) ;  
- **Politiques CA/PIM** (filtrage par groupes dynamiques) ;  
- **Délégations AUs**.

### 3.2 Synchronisation & ancrage
- **Entra Connect** : `mS-DS-ConsistencyGuid` comme *sourceAnchor*.  
- **Scoping** : PRD (objets licenciés) ; DEV/TST et comptes *Admin* non licenciés ou *sign-in blocked*.  
- **Un objet Entra ID par personne** (licencié), **plusieurs comptes ADDS** liés via extensionAttributes.

---

## 4. Flux détaillés (T2 / T1 / T0)

### 4.1 T2 — Provisioning standard (licence unique)
1) **IIQ** déclenche le cycle LCM (create/update).  
2) **Orchestrateur** applique le mapping (OU, groupes, attributs).  
3) **AD DS (PRD)** : compte utilisateur créé/mis à jour.  
4) **Connect** synchronise vers **Entra ID** (objet cloud unique).  
5) **Graph** (via orchestrateur) enrichit `extensionAttribute10..13`.  
6) **Entra ID** : affectation **licence** ; **groupes dynamiques** ; **CA** appliquée.

**Règle de groupe dynamique (ex.)**
```text
(user.extensionAttribute10 -eq "T2") and (user.extensionAttribute11 -eq "PRD")
```

### 4.2 T1 — Accès privilégié JIT (PAW T1, PSM, JEA)
1) **IIQ** : demande d’accès admin T1 avec justification ; approbation IAM.  
2) **Orchestrateur** (webhook) → **PVWA** (JIT request).  
3) **Admin** se connecte **via PAW T1** → **PVWA** → **PSM** vers **Bastion T1**.  
4) **JEA T1** (endpoint) restreint les cmdlets autorisées.  
5) **Optionnel** : appartenance JIT à un groupe AD (retrait auto en fin de session).  
6) **Clôture** : check-in et rotation des secrets ; logs PSM/PowerShell → SIEM.

### 4.3 T0 — Accès privilégié critique (PAW T0, double approbation)
1) **IIQ** : demande T0 (double approbation IAM + SecOps).  
2) **PVWA** : JIT + PSM vers **Bastion T0**.  
3) **JEA T0** : surface minimale (cmdlets critiques seulement), WDAC/ASR/LSA PPL.  
4) **Clôture** : rotation stricte ; revue post-session.

---

## 5. Conception des contrôles (EAM, PIM, CA, JEA, PAW)

### 5.1 EAM (tiering)
- **T2** : utilisateurs et helpdesk ;  
- **T1** : admins serveurs/applicatifs ;  
- **T0** : identité, PKI, domaines, connecteurs.  
Isolation stricte des chemins d’administration, **pas de pivot T2→T0** [2].

### 5.2 PIM (eligible-only) & approbations
- Rôles cloud (Entra ID) en **mode eligible** seulement.  
- **Approbations** et **durées courtes** (T1 ≤ 120 min, T0 ≤ 60 min).  
- Justification et ticketing obligatoires.

### 5.3 Conditional Access (CA)
- **PAW-only** pour portails admin ; **MFA** systématique ; **device compliant**.  
- Session control (Defender for Cloud Apps) : **block download**, **watermark**.

**Exemple (JSON extrait, cf. `policies/conditional-access/*`)**
```json
{
  "displayName": "CA-PIM-Activation-PAW-Only",
  "state": "enabled",
  "grantControls": { "operator": "AND", "builtInControls": ["mfa","compliantDevice"] }
}
```

### 5.4 JEA (Just Enough Administration)
- Endpoints **T1** et **T0** avec `RoleCapabilities` stricte.  
- **Transcripts** et logs vers SIEM ; **PSM recording** actif.  
- **WDAC/ASR** : restriction d’exécution ; **LSA PPL**.

**Extrait pssc (T1)**
```powershell
@{
  SchemaVersion = '2.0.0.0'
  SessionType   = 'RestrictedRemoteServer'
  TranscriptDirectory = 'C:\JEA\Transcripts\T1'
  RoleDefinitions = @{
    'DOMAIN\\JEA-T1-Operators' = @{ RoleCapabilities = 'JEA.AD.T1' }
  }
}
```

### 5.5 PAW (Privileged Access Workstations)
- **Séparées** du poste utilisateur.  
- **Durcies** (GPO, EDR, WDAC, ASR).  
- **Restreintes** aux portails, PVWA, bastions.

---

## 6. Orchestration & intégrations

### 6.1 Orchestrateur (GitHub Actions → Ansible)
- **Runners** T1 (self-hosted) ; secrets via OIDC/KeyVault.  
- **Playbooks** : provisioning T2, JIT T1/T0, intégration PVWA (API).

**Extrait GitHub Actions**
```yaml
name: Update Entra extensionAttributes
on: { workflow_dispatch: {} }
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

**Extrait Ansible (PVWA JIT)**
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
      reason: "JIT via IIQ"
```

### 6.2 Intégrations IIQ ↔ Entra ID
- **SCIM** pour identité de base ;  
- **Graph PATCH** pour `extensionAttributeX`.  
- **Mapping** versionné (`integration/entra-extension-attributes/iiq_scim_mapping.csv`).

---

## 7. Modèle Entra ID : AUs, Groupes dynamiques, Licences

### 7.1 Administrative Units (AUs)
- AUs **par environnement** (`AU-PRD-Tx`, `AU-DEV-Tx`, `AU-TST-Tx`) et **par tier**.  
- Délégations **moindre privilège** (helpdesk T2, ops T1, core T0).  
- Exemples JSON : `entra/administrative-units/*.json`.

### 7.2 Groupes dynamiques
- Règles **sur extensionAttributes** (tier/env/type).  
- Pilotage des **CA/PIM** par appartenance dynamique.  
- Exemples : `integration/entra-dynamic-groups/*.json`.

### 7.3 Licences
- **T2 uniquement** (1 licence par personne).  
- Comptes **Admin** non licenciés (standing access interdit).

---

## 8. Sécurité transversale & réseau

### 8.1 Segmentation & flux
- **PSM only** vers bastions ;  
- **PAW-only** vers PVWA, Entra ;  
- **Ports** : WinRM (5985/5986) vers JEA ; RDP proxifié via PSM ; HTTPS (443) vers portails/API.

### 8.2 Journalisation & SIEM
- PSM vidéo + PowerShell transcripts + Connect sync logs + Graph audit.  
- Corrélation **Splunk** (`observability/splunk/dashboard_identity_jit.xml.json`) ;  
- KPI **Grafana** (`observability/grafana/dashboard_kpis.json`).

### 8.3 Conformité
- Contrôles **NIST 800-53** AC/IA/AU [3] ;  
- **Zero Trust** (NIST 800-207) [1] ;  
- **CIS v8** AD Admin [4] ;  
- **ISO/IEC 27001:2022** [6] ;  
- **NIST CSF 2.0** [7].

---

## 9. Disponibilité & continuité

### 9.1 Résilience
- PVWA/PSM HA, Connect staging, runners redondés.  
- Sauvegardes de config (Vault, Graph app reg, IIQ export).

### 9.2 Break-glass
- Runbook **T0** (double approbation, durée ≤ 30 min, rotation post-usage) : `runbooks/RUNBOOK_BREAKGLASS_T0.md`.

---

## 10. Annexes techniques

### 10.1 Diagrammes (répertoire `diagrams/`)
- `tier2_provisioning.puml`, `tier1_admin_access.puml`, `tier0_admin_access.puml`, `jea_mechanics.puml`  
- `c4_highlevel.puml`, `c4_layers_defense_in_depth.puml`

### 10.2 Exemples de configuration (extraits)
- **Graph PATCH PowerShell** : `integration/entra-extension-attributes/graph_update_example.ps1`  
- **GitHub Actions** : `integration/entra-extension-attributes/graph_update_example.yml`  
- **SCIM payload** : `integration/entra-extension-attributes/scim_payload_example.json`  
- **Conditional Access JSON** : `policies/conditional-access/*.json`  
- **MDA session control** : `policies/defender-for-cloud-apps/*.json`  
- **PIM exports** : `policies/pim/*.json`

---

## 11. Références normatives
- [1] **NIST SP 800-207** — Zero Trust Architecture  
- [2] **Microsoft EAM (Enterprise Access Model)** — Tiering T0–T2  
- [3] **NIST SP 800-53 rev5** — Contrôles AC/IA/AU  
- [4] **CIS Controls v8** — AD Admin  
- [5] **MITRE ATT&CK** — TTP Windows  
- [6] **ISO/IEC 27001:2022** — SGSI  
- [7] **NIST CSF 2.0** — Identify/Protect/Detect/Respond/Recover
