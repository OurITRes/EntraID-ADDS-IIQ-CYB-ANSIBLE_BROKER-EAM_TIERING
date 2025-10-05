# ENTRA ID – Cloud Identity Management

## 1. Objectif
Entra ID fournit la couche **d’identité cloud unifiée**.  
Il gère les comptes standard (T2), les groupes dynamiques, les Administrative Units (AU) et les rôles PIM pour les administrateurs éligibles.

## 2. Architecture
- **Tenant unique** : enrôlement multi-subscriptions (Azure, M365).  
- **Administrative Units** : segmentation par environnement (DEV, TST, PRD).  
- **PIM (Privileged Identity Management)** : gestion éligible des rôles globaux.  
- **Conditional Access** : contrôle d’accès contextuel (MFA, localisation, device).  

## 3. Modèle d’intégration
| Composant | Rôle | Lien avec IIQ / CyberArk |
|------------|------|--------------------------|
| Dynamic Groups | Affectation automatique d’accès | IIQ via extensionAttribute |
| PIM | Activation temporaire des rôles | IIQ / CyberArk |
| Administrative Units | Scopes délégués par Tier | IIQ / Orchestrateur |
| Conditional Access | Sécurité adaptative | CyberArk / Entra Logs |

## 4. Licences et identité unique
Seuls les utilisateurs standards (T2) consomment une licence Entra ID.  
Les comptes admin T1/T0 sont sans licence, créés temporairement par IIQ → CyberArk.  

## 5. Références normatives
- NIST PR.AC-1 / PR.AC-7  
- ISO 27001 A.9.2.1 (User registration and de-registration)  
- CIS Control 6 (Access Control)  
- Microsoft EAM – Tiering & PIM
