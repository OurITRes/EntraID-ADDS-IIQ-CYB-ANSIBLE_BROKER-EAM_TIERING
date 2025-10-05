# Vault_Security_and_Audit – Exigences & Vérifications

La **CyberArk Digital Vault** est **hors EAM** (non jointe au domaine) et agit comme **racine de confiance**.  
Objectif : empêcher toute compromission via durcissement + contrôles d’audit.

## 1. Exigences de sécurité (synthèse)

| Domaine | Exigence | Détails |
|--------|---------|--------|
| Isolation | Hors domaine AD, pas de session interactive | Pas de trust ; accès uniquement via PVWA/CPM/PSM |
| Réseau | Ports 1858/1859 uniquement, liste blanche | Aucune exposition directe aux utilisateurs |
| OS | Windows Server durci, patch mensuel | Services minimaux, RDP fermé par défaut |
| Crypto | AES‑256, FIPS 140‑2, HSM recommandé | Re‑key annuel des safes |
| Comptes | Locaux uniquement (Operators, Master) + MFA | Two‑man rule pour opérations critiques |
| DR | DR Vault chiffrée, réplication unidirectionnelle | Clé de restauration hors site |
| Logs | SIEM lecture seule + EDR T0 | Tamper‑proof, alertes corrélées |

## 2. Références normatives
- NIST SP 800‑53 rev5 (SC‑12, SC‑28, AC‑6, CP‑9)  
- CIS Controls v8 #3, #5, #7  
- ISO/IEC 27001:2022 A.9.4.3  
- CyberArk Hardening Guide v13.x

## 3. Script de validation (Windows PowerShell)

Fichier : `scripts/validate_vault_security.ps1`

Vérifie :  
- Non appartenance au domaine AD,  
- Ports ouverts (1858/1859),  
- Mode FIPS,  
- Signature du binaire PrivateArk,  
- Services et patching,  
- Présence d’un compte local seulement (indicatif).

## 4. Fréquence d’audit
- **Mensuel** : exécution automatisée du script et archivage du rapport.  
- **Semestriel** : test DR Vault + revue clés.  
- **Annuel** : re‑keying safes + revue complète durcissement.
