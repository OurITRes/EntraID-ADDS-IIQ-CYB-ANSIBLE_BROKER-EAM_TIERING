# CYBERARK – Privileged Access Security

## 1. Objectif
CyberArk protège et trace **l’ensemble des comptes à privilèges** (T0, T1) de la plateforme EntraID–ADDS–IIQ.  
Il garantit que **chaque session administrative est temporaire, contrôlée et auditée**.

## 2. Architecture fonctionnelle
- **Vault** : stockage chiffré des identifiants privilégiés.  
- **PSM (Privileged Session Manager)** : isolation et enregistrement des sessions.  
- **PVWA (Portal)** : interface utilisateur et API pour demandes d’accès.  
- **CPM (Credential Provider Manager)** : rotation automatique des mots de passe.  

## 3. Modèle d’accès
| Type de compte | Tier | Gestion | Durée d’accès | Source |
|----------------|------|----------|----------------|---------|
| Administrateur domaine | T0 | CyberArk Safe + JEA | 60 min | IIQ / Orchestrateur |
| Administrateur serveur | T1 | CyberArk Safe | 120 min | IIQ / Ansible |
| Utilisateur standard | T2 | Non applicable | Permanente | IIQ → Entra ID |

## 4. Intégration avec IIQ et Entra ID
- IIQ crée les comptes T1/T0 via API orchestrée.  
- CyberArk génère un identifiant unique et stocke les secrets.  
- Entra ID applique les policies Conditional Access pour les sessions PSM.  

## 5. Contrôles de sécurité
- MFA obligatoire avant toute session PSM.  
- Rotation automatique à chaque fin de session.  
- Logs détaillés (`/vault/logs/psm_sessions.json`).  
- Intégration SOC via Splunk pour corrélation des anomalies.

## 6. Références normatives
- NIST PR.AC-6 (Least Privilege)
- CIS Control 5 (Account Management)
- ISO 27001 A.9.4.3 (Use of privileged utilities)
