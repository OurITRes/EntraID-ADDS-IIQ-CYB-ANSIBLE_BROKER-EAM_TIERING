
---

### Note importante — CyberArk Vault (Hors EAM)
La **CyberArk Digital Vault** constitue le **root of secrets** et n’est **pas** intégrée à la forêt AD (🚫 hors EAM).  
Les composants **PVWA/CPM/PSM** (T0) y accèdent via des **flux chiffrés** et **liste blanche d’origines**.  
Exigences : isolement réseau, OS durci, comptes locaux MFA, chiffrement AES‑256/HSM, réplication DR chiffrée unidirectionnelle.
