# FAQ – Questions fréquentes

### Q1 : Pourquoi IIQ ne gère-t-il pas directement les comptes T0 ?
Parce que IIQ est positionné en **Tier 1**, et ne peut pas accéder directement aux ressources T0.  
Les demandes T0 passent par un **orchestrateur Ansible** et **CyberArk** pour garantir la segmentation EAM.

### Q2 : Comment les comptes administrateurs temporaires sont-ils supprimés ?
Chaque compte T1/T0 créé via CyberArk a une durée de vie limitée (60–120 min).  
À l’expiration, le compte est désactivé puis supprimé automatiquement par un playbook Ansible.

### Q3 : Quels logs sont utilisés pour les audits ?
- IIQ : LCM et Certification Reports  
- CyberArk : PSM / PVWA / Vault rotation logs  
- Entra ID : Sign-in et Conditional Access  
- ADDS : PowerShell + PingCastle  
- Tous centralisés dans Splunk / Datadog

### Q4 : Comment prouver la conformité GDPR ?
Par les exports automatisés d’anonymisation, les rapports GRC et les logs SIEM corrélés.  
Le DPO et le GRC Officer valident chaque trimestre la conformité PII.

### Q5 : Quelle est la fréquence des revues de conformité ?
- Technique : mensuelle (SOC)  
- Organisationnelle : trimestrielle (COS)  
- Stratégique : semestrielle (CSI)
