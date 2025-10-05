# IIQ – Identity Governance and Administration

## 1. Objectif et rôle
SailPoint IdentityIQ (IIQ) constitue la **colonne vertébrale du contrôle des identités** au sein de l’architecture EntraID–ADDS–CyberArk.  
Son rôle : orchestrer la création, la gouvernance et la suppression des comptes, en garantissant le respect du modèle **Enterprise Access Model (EAM)** et du **tiering Microsoft (T0–T2)**.

## 2. Fonctions principales
- **Provisioning automatisé** des comptes standard (T2) dans Entra ID et ADDS.  
- **Workflow d’approbation** multi-niveaux pour les accès sensibles (T1/T0).  
- **Certification des accès** périodique selon les exigences ISO A.9.2.5.  
- **Détection des conflits de séparation des tâches (SoD)**.  
- **Intégration orchestrateur Ansible/GitHub Actions** pour le maintien du tiering.  

## 3. Flux de provisioning
1. IIQ reçoit la demande (HR feed ou utilisateur).  
2. Vérification du type de compte (standard ou admin).  
3. Si admin (T1/T0), IIQ envoie la requête à l’orchestrateur (Ansible) → CyberArk.  
4. CyberArk gère la création sécurisée et la rotation du compte.  
5. IIQ consomme le retour d’état et met à jour l’audit trail.  

## 4. Intégrations clés
| Système | Rôle | Mode d’intégration |
|----------|------|--------------------|
| Entra ID | Gestion des groupes dynamiques et SCIM | API Graph |
| ADDS | Synchronisation et mapping des OU | Agent LDAP / PowerShell |
| CyberArk | Provisioning et JIT admin | REST API / PVWA |
| Ansible | Orchestration non-T0 | API REST et webhook GitHub |

## 5. Gouvernance et conformité
IIQ alimente directement la **matrice de conformité GRC** (`/reports/compliance_report.json`).  
Chaque action de provisioning est signée et auditable (`/audit/evidences/IIQ_*`).

## 6. Références normatives
- NIST PR.AC-1 à PR.AC-5 (Access Control)
- ISO/IEC 27001 A.9 (Access Management)
- CIS Control 6 (Access Control Management)
- Microsoft EAM (Tiering identitaire)
