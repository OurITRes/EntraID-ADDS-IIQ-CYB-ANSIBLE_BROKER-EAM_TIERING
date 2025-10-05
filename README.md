# Entra ID × SailPoint IIQ × AD DS (Multi-forêts) — Tiering EAM (T2/T1/T0)

Ce dépôt fournit **3 diagrammes de séquence PlantUML** + **1 diagramme JEA** et toute la **documentation** pour opérer un modèle où :
- **IIQ** (Tier‑1) orchestre le **provisioning T2** (users licenciés Entra ID), et **les accès JIT** pour **T1** et **T0** via **CyberArk (PVWA/PSM)** + **JEA** ;
- Les **comptes admin** n’ont **aucun standing access** ni licence ;
- **PAW T1/T0**, **PIM/CA**, **JEA**, **délégations OU**, **scoping Entra Connect** assurent la séparation **EAM (T2/T1/T0)**.


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
