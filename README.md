# Entra ID × SailPoint IIQ × AD DS (Multi-forêts) — Tiering EAM (T2/T1/T0)

Ce dépôt fournit **3 diagrammes de séquence PlantUML** + **1 diagramme JEA** et toute la **documentation** pour opérer un modèle où :
- **IIQ** (Tier‑1) orchestre le **provisioning T2** (users licenciés Entra ID), et **les accès JIT** pour **T1** et **T0** via **CyberArk (PVWA/PSM)** + **JEA** ;
- Les **comptes admin** n’ont **aucun standing access** ni licence ;
- **PAW T1/T0**, **PIM/CA**, **JEA**, **délégations OU**, **scoping Entra Connect** assurent la séparation **EAM (T2/T1/T0)**.
#  Nouveautés de la v0.1.4-beta (par rapport à v0.1.3-beta)

## Version 0.1.4-beta
- **Defender for Cloud Apps** : contrôles de session pour portails admin → `policies/defender-for-cloud-apps/`
- **Terraform** : dynamic groups + Conditional Access → `terraform/`
- **Ansible PVWA API** : playbook `grant_t1_jit_pvwa_api.yml` (appel réel via `uri`) → `playbooks/t1_admin/`
- **Runbook Break-glass T0** → `runbooks/RUNBOOK_BREAKGLASS_T0.md`
- **Grafana KPIs** → `observability/grafana/dashboard_kpis.json`

## 🧩 Defender for Cloud Apps (Session Control)

**Fichier :**
`policies/defender-for-cloud-apps/MDA-Admin-Portals-Restrict-Downloads.json`

**Description :**
- Restreint les **téléchargements** sur les portails administratifs (Azure, Entra, M365).  
- Implique le **monitoring** et le **watermarking** des sessions sensibles.  
- Ciblage précis via **groupe dynamique** des administrateurs.  
- Objectif : éviter toute fuite de données depuis les consoles d’administration.

## 🧱 Terraform (Infrastructure as Code – exemples)

**Répertoire :** `terraform/`

### Contenu :

- **`providers.tf`**  
  Déclare les providers :
  - `azuread`
  - `microsoft365`

- **`dynamic_groups.tf`**  
  Définit un **groupe dynamique T1/PRD** basé sur les attributs :
  - `extensionAttribute10`
  - `extensionAttribute11`

- **`conditional_access.tf`**  
  Exemple de politique de **Conditional Access** :
  - “PIM activation PAW-only”  
  - Restreint les activations PIM aux **Postes d’Administration Sécurisés (PAW)** uniquement.

- **`outputs.tf`**  
  Exporte les **IDs utiles** (groupes, policies, objets).

💡 *Ces fichiers sont à adapter selon la configuration des providers de Conditional Access (les capacités évoluent rapidement).*


## ⚙️ Ansible (API PVWA – intégration réelle)

**Fichier :**
`playbooks/t1_admin/grant_t1_jit_pvwa_api.yml`

**Fonction :**
- Effectue un **appel HTTP** (module `uri`) vers :
/PasswordVault/API/Accounts/<id>/Requests

markdown
Copy code
- Variables d’environnement :
- `PVWA_BASE_URL`
- `PVWA_TOKEN`
- Permet une **demande d’accès JIT (Just-In-Time)** via API pour les comptes T1, intégrée au modèle de rôles CyberArk.


## 🚨 Runbook Incident (Break-Glass T0)

**Fichier :**
`runbooks/RUNBOOK_BREAKGLASS_T0.md`

**Objectif :**
- Procédure **critique P1** pour gestion d’incident majeur sur Tier 0.  
- Étapes clés :
1. Accès via **HSM/coffre-fort** sécurisé.  
2. Signature **2-of-3** (approbation multi-personnes).  
3. Utilisation d’un **bastion restreint**.  
4. Création d’un **compte d’urgence temporaire**.  
5. Journalisation en **WORM** (Write-Once-Read-Many).  
6. **Post-mortem** obligatoire après résolution.


## 📊 Grafana Dashboard (KPIs Sécurité & Gouvernance)

**Fichier :**
`observability/grafana/dashboard_kpis.json`

**Indicateurs clés :**
- % d’administrateurs **sans accès permanent (standing access)**  
- **Temps moyen d’approbation** des demandes PIM/PVWA  
- Nombre de **sessions PSM** par jour  
- **Licences évitées** grâce aux accès temporaires et à l’automatisation

🎯 *Objectif : fournir une visibilité consolidée sur la posture Zero Standing Privilege (ZSP) et la gouvernance des accès à privilèges.*

---

## Version 0.1.3-beta

# Nouveautés de la v0.1.3-beta (par rapport à v0.1.2-beta)

- Entra ID — Groupes dynamiques (exemples JSON) integration/entra-dynamic-groups/
  - dynamic_group_T1_PRD.json : règle (user.extensionAttribute10 -eq "T1") and (user.extensionAttribute11 -eq "PRD")
  - dynamic_group_Admin_ANY.json : règle (user.extensionAttribute12 -eq "Admin")
- Conditional Access — Politiques exemples (JSON) policies/conditional-access/
  - CA-PIM-Activation-PAW-Only.json : MFA + device compliant + PAW-only pour activer PIM
  - CA-Admin-Block-Non-PAW.json : block tout accès admin hors PAW
- Observabilité — Dashboard Splunk (corrélation e2e) observability/splunk/dashboard_identity_jit.xml.json
  - Panneaux : IIQ Requests, PVWA Sessions, AD Changes via JEA, Entra ID Updates (Graph)
  - Requêtes type stats prêtes à adapter à tes index/sourcetypes

---

## 🆕 Version 0.1.2-beta

## 📁 Structure
```
ROOT/
├─ diagrams/                                # (V2)
│  ├─ tier2_provisioning.puml               # T2 standard (licencié Entra ID)
│  ├─ tier1_admin_access.puml               # T1 JIT via PAW T1 + PVWA/PSM + JEA-T1
│  ├─ tier0_admin_access.puml               # T0 JIT via PAW T0 + double appro + JEA-T0
│  └─ jea_mechanics.puml                    # Mécanique JEA
├─ jea/                                     # (V2)
│  ├─ T1/RoleCapabilities/JEA.AD.T1.psrc
│  ├─ T1/SessionConfigurations/JEA.AD.T1.pssc
│  ├─ T0/RoleCapabilities/JEA.AD.T0.psrc
│  └─ T0/SessionConfigurations/JEA.AD.T0.pssc
├─ playbooks/                               # (V2) Ansible par tier
│  ├─ t2_standard/provision_t2.yml
│  ├─ t1_admin/grant_t1_jit.yml
│  └─ t0_admin/grant_t0_jit.yml
├─ scripts/ps/                              # (V2) Helpers PowerShell
│  ├─ Invoke-ADUserProvision.ps1
│  ├─ JEA-T1-AdminTasks.ps1
│  └─ JEA-T0-AdminTasks.ps1
├─ inventory/                               # (V2) INI d’exemples
│  ├─ t2.ini
│  ├─ t1.ini
│  └─ t0.ini
├─ integration/
│  └─ entra-extension-attributes/
│     ├─ scim_payload_example.json          # Exemple SCIM IIQ → Entra
│     ├─ graph_update_example.ps1           # PowerShell Graph SDK (PATCH ext attrs)
│     ├─ graph_update_example.yml           # Workflow GitHub Actions (Graph via az rest)
│     ├─ iiq_scim_mapping.csv               # Mapping IIQ → extensionAttributes
│     ├─ app_registration_min.json          # App reg minimal (User.ReadWrite.All)
│     ├─ PVWA.postman_collection.json       # Postman: JIT & PSM connect (placeholders)
│     └─ README.md                          # Explications + sécurité + groupes dynamiques
├─ docs/                                    # Nouvelles docs par audience
│  ├─ BUSINESS.md       # valeur d’affaires, KPIs, roadmap
│  ├─ ARCHITECTURE.md   # vues, tiers, flux privilégiés
│  ├─ IMPLEMENTATION.md # étapes pratiques (Connect, JEA, Orchestrateur, PVWA)
│  ├─ DEVELOPERS.md     # API Graph/SCIM, Postman, intégrations
│  ├─ ENTRA.md          # AUs, PIM, CA, licences
│  ├─ IIQ.md            # Workflows, connecteurs, recertifications
│  ├─ CYBERARK.md       # Policies, PSM sessions, onboarding
│  ├─ SECURITY.md       # Zero Trust, no standing access, MFA, logs
│  ├─ GOVERNANCE.md     # décisions, recerts, KPI/OKR, break-glass
│  ├─ GLOSSARY.md       # vocabulaire (EAM, PIM, JEA, etc.)
│  └─ FAQ.md            # questions fréquentes
├─ .github/workflows/
│  ├─ render-plantuml.yml                   # (V2) Rend les .puml en PNG
│  └─ ansible-dry-run.yml                   # NEW: dry-run de playbooks T2/T1/T0
├─ .env.example                             # Secrets/vars attendues (Graph, PVWA)
├─ .gitignore
└─ README.md                                # (V2 + rappel)
```

## Ajout de la documentation
- Business / exécutifs → docs/BUSINESS.md (valeur d’affaires, KPI, roadmap).
- Architectes → docs/ARCHITECTURE.md, diagrams/*.puml.
- Ops / Implémentation → docs/IMPLEMENTATION.md, playbooks/*, jea/*.
- Dev / Intégrations → docs/DEVELOPERS.md, integration/*, Postman, Graph/SCIM.
- Entra ID → docs/ENTRA.md (AUs, PIM, CA, licences).
- IIQ → docs/IIQ.md (workflows, connecteurs, recerts).
- CyberArk → docs/CYBERARK.md (policies, PSM, onboarding, JIT).
- Sécurité & Gouvernance → docs/SECURITY.md, docs/GOVERNANCE.md.
- Tout le monde → docs/GLOSSARY.md, docs/FAQ.md.

## Conseils de prod
- **Graph App Reg** : scope minimal (User.ReadWrite.All), secret court, rotation, pas de Global Admin.
- **CI/CD** : garde les workflows “dry-run” tant que le bastion/JEA/PVWA de prod n’est pas raccordé.

---

## 🆕 Version 0.1.1-beta — Ajouts majeurs (séparés par T2 / T1 / T0 / standard)

## 📁 Structure
```
ROOT/
├─ diagrams/
│  ├─ tier2_provisioning.puml
│  ├─ tier1_admin_access.puml
│  ├─ tier0_admin_access.puml
│  └─ jea_mechanics.puml
├─ jea/
│  ├─ T1/
│  │  ├─ RoleCapabilities/JEA.AD.T1.psrc
│  │  └─ SessionConfigurations/JEA.AD.T1.pssc
│  └─ T0/
│     ├─ RoleCapabilities/JEA.AD.T0.psrc
│     └─ SessionConfigurations/JEA.AD.T0.pssc
├─ playbooks/
│  ├─ t2_standard/provision_t2.yml
│  ├─ t1_admin/grant_t1_jit.yml
│  └─ t0_admin/grant_t0_jit.yml
├─ scripts/ps/
│  ├─ Invoke-ADUserProvision.ps1
│  ├─ JEA-T1-AdminTasks.ps1
│  └─ JEA-T0-AdminTasks.ps1
├─ inventory/
│  ├─ t2.ini
│  ├─ t1.ini
│  └─ t0.ini
├─ docs/
│  └─ CyberArk-PVWA-API.md
├─ .github/workflows/
│  └─ render-plantuml.yml
├─ .gitignore
└─ README.md
```

### ✅ JEA (Just Enough Administration)
- `jea/T1/RoleCapabilities/JEA.AD.T1.psrc` & `jea/T1/SessionConfigurations/JEA.AD.T1.pssc`
- `jea/T0/RoleCapabilities/JEA.AD.T0.psrc` & `jea/T0/SessionConfigurations/JEA.AD.T0.pssc`  
> **À faire côté bastion** : copier les `.psrc` dans `C:\ProgramData\JEA\RoleCapabilities\`, les `.pssc` où souhaité, puis :
```powershell
Register-PSSessionConfiguration -Name JEA-AD-T1 -Path C:\Path\To\JEA.AD.T1.pssc -Force
Register-PSSessionConfiguration -Name JEA-AD-T0 -Path C:\Path\To\JEA.AD.T0.pssc -Force
```
Les transcripts sont dans `C:\JEA\Transcripts\T1|T0` (à expédier vers SIEM).

### ✅ Ansible — Playbooks par **tier**
- `playbooks/t2_standard/provision_t2.yml`
- `playbooks/t1_admin/grant_t1_jit.yml`
- `playbooks/t0_admin/grant_t0_jit.yml`

### ✅ Inventaires
- `inventory/t2.ini`, `inventory/t1.ini`, `inventory/t0.ini`

### ✅ Scripts PowerShell
- `scripts/ps/Invoke-ADUserProvision.ps1` (T2 provisioning helper)
- `scripts/ps/JEA-T1-AdminTasks.ps1` (exemple de commande sous JEA-T1)
- `scripts/ps/JEA-T0-AdminTasks.ps1` (exemple de commande sous JEA-T0)

### ✅ Docs
- `docs/CyberArk-PVWA-API.md` (endpoints clés & conseils)

---

## 🚦 Bonnes pratiques d’usage
- **Ne pas** élargir les cmdlets visibles dans les `.psrc` sans revue Sécu.
- Toujours exécuter **T0** via **PSM + JEA-T0**, **double approbation** côté PVWA.
- Les playbooks T1/T0 contiennent des **placeholders** pour l’API PVWA : branchez vos appels `uri`/SDK selon votre config.
- Entra Connect reste scoppé : **1 forêt autoritaire** pour l’objet cloud licencié (T2 uniquement).

---

## 🆕 Version 0.1.0-beta

## 📁 Structure
```
.
├─ diagrams/
│  ├─ tier2_provisioning.puml       # IIQ provisionne comptes T2 + licence Entra ID
│  ├─ tier1_admin_access.puml       # IIQ demande accès T1 JIT (PAW T1)
│  ├─ tier0_admin_access.puml       # IIQ demande accès T0 JIT (PAW T0, double approbation)
│  └─ jea_mechanics.puml            # Mécanique JEA (role capability + session config)
└─ .github/workflows/
   └─ render-plantuml.yml           # CI pour rendre PNG à partir des .puml
```

## 🧩 Hypothèses clés
- **Seuls les comptes T2 (users)** sont **licenciés Entra ID** (1 licence/personne).
- Les **comptes admin** (`a-<user>`, `a-<user0>`) sont **non licenciés** et **sans standing access** ; accès **JIT** via **PVWA/PSM** & **JEA**.
- **IIQ reste Tier‑1** : pas d’actions directes T0 ; toutes les opérations T0 passent par **PSM + JEA**.
- **Entra Connect** : **une seule forêt “source autoritaire”** pour l’objet cloud licencié (PRD), filtrage OU/attributs pour DEV/TST/Admin.

## 🛡️ Checklist de mise en œuvre (résumé)
### Gouvernance & Identité
- IIQ = source of truth (mapping identité ↔ comptes T2 & admin).
- Stratégie 1 licence/personne (T2 seulement).
- Admin sans standing access ; naming & tags `extensionAttribute*` (tier/env/type).

### Synchronisation & Cloud
- Entra Connect/Cloud Sync : 1 forêt autoritaire, filtres d’exclusion pour admin/DEV/TST, `mS-DS-ConsistencyGuid` → `ImmutableID`.
- SCIM/Graph pour `extensionAttributes` et métadonnées.

### Orchestration (CI/CD)
- Runner GitHub Actions **Tier‑1**, **Ansible** playbooks (T2/T1/T0) idempotents.
- Zéro secret en clair : **PVWA JIT tickets**, rotation post‑op.

### CyberArk
- PVWA : SSO (MFA), approbations ; PSM/PSMP : brokering + session recording.
- JIT group membership (si utilisé) : ajout/retrait auto.
- Politiques T0 : **double approbation**, fenêtre courte, justification.

### AD DS
- Délégations OU pour T2 (droits précis, pas DA).
- OU Admin T0 : AdminSDHolder, FGPP admin, Kerberos AES‑only.
- Groupes T1/T0 dédiés (pas DA direct), vides par défaut.
- “No standing access” : opérations via JEA/PSM/JIT seulement.

### JEA
- Role Capability `.psrc` (cmdlets whitelistées) ; Session Config `.pssc` (mapping groupes → rôles).
- Endpoints séparés `JEA-AD-T1` / `JEA-AD-T0`, transcriptions signées, logs vers SIEM.

### PAW & CA/PIM
- PAW T1/T0 gérés (Intune), réseau segmenté ; accès sensibles **PAW‑only** via **Conditional Access**.
- PIM en “eligible only”, MFA, approbations, durée 30–120 min (T0 ≤ 60).

### Journalisation & DR
- PSM recording + PowerShell transcription + ETW/Sysmon → SIEM.
- Runbooks standard, break‑glass T0, sauvegardes configs IIQ/PVWA/JEA.

> Voir les 3 séquences `.puml` pour le détail des flux et `jea_mechanics.puml` pour la mécanique JEA.

## 🚀 CI : rendu automatique des diagrammes
Le workflow suivant rend les `.puml` en **PNG** à chaque `push` :
- Utilise l’action `TimonVS/plantuml-action` (sans secrets).
- Écrit les PNG **dans le même dossier `diagrams/`**.

## 🧪 Tests et validations
- Valider les playbooks Ansible en dry‑run (`--check`).
- Tester un flux bout‑en‑bout **T2**, puis **T1 (JIT)**, puis **T0 (JIT + double appr.)**.
- Vérifier que **aucune** appartenance permanente n’est laissée après expiration.

---

© 2025 — Architecture de référence Entra ID × IIQ × AD DS (EAM T2/T1/T0).


---