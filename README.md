# Entra ID × SailPoint IIQ × AD DS (Multi-forêts) — Tiering EAM (T2/T1/T0)

Ce dépôt fournit **3 diagrammes de séquence PlantUML** + **1 diagramme JEA** et toute la **documentation** pour opérer un modèle où :
- **IIQ** (Tier‑1) orchestre le **provisioning T2** (users licenciés Entra ID), et **les accès JIT** pour **T1** et **T0** via **CyberArk (PVWA/PSM)** + **JEA** ;
- Les **comptes admin** n’ont **aucun standing access** ni licence ;
- **PAW T1/T0**, **PIM/CA**, **JEA**, **délégations OU**, **scoping Entra Connect** assurent la séparation **EAM (T2/T1/T0)**.

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

## 🔧 Visualiser les diagrammes
### Option A — VS Code (recommandé en local)
1. Installer **Visual Studio Code**.
2. Extensions : **PlantUML**.
3. Installer **Graphviz** (mac: `brew install graphviz`, Windows: site Graphviz).
4. Ouvrir un `.puml` → “Preview Current Diagram” (`Alt+D`) → Export PNG/SVG si besoin.

### Option B — GitHub + CI (auto‑rendu)
Le workflow CI rendra automatiquement des **PNG** dans `diagrams/` à chaque push (voir `.github/workflows/render-plantuml.yml`).

### Option C — Online (à éviter pour contenu sensible)
- planttext.com ou plantuml.com/plantuml/uml/

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
