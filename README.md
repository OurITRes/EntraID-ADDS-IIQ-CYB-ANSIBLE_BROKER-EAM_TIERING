# EntraID–ADDS–IIQ–CyberArk–Ansible Broker – EAM Tiering v1.0

> 💬 *“Never trust, always verify.” — NIST Zero Trust Architecture (SP 800-207)*  
> 💬 *“Security is the foundation of trust.” — Satya Nadella, Microsoft CEO*

**Projet mené dans le cadre de la modernisation sécurisée des identités hybrides multi-cloud, selon les principes Zero Trust, NIST SP 800-53 rev5, CIS v8 et Microsoft EAM.**

---

## 🌐 Introduction

Ce dépôt représente le **socle documentaire et technique complet** d’un environnement d’identité unifiée reposant sur la convergence de :

- **Entra ID (Azure AD)** : gestion de l’identité cloud, PIM, Conditional Access, Administrative Units.  
- **Active Directory Domain Services (ADDS)** : fondation on-premises, mono-forêt, tiering T0–T2.  
- **SailPoint IdentityIQ (IIQ)** : moteur de gouvernance et d’orchestration des identités.  
- **CyberArk PAS / PSM** : coffre-fort et bastion pour les accès privilégiés.  
- **Ansible / GitHub Actions** : orchestrateurs pour l’automatisation, l’auditabilité et la conformité.  

L’objectif : **garantir une identité unique, gouvernée et traçable**, tout en respectant la segmentation des privilèges et la défense en profondeur.

---

## 🧭 Vision et principes

L’architecture s’appuie sur :

- la **modélisation Enterprise Access Model (EAM)** : séparation stricte T0 / T1 / T2 ;  
- la **philosophie Zero Trust** : authentification systématique, moindre privilège, vérification continue ;  
- la **gouvernance intégrée** : conformité = processus vivant ;  
- la **sécurité par le design et par l’automatisation**.

Ce dépôt décrit à la fois la **vision stratégique**, la **mise en œuvre technique**, la **gouvernance documentaire** et les **mécanismes d’audit et de conformité**.

---

## 📚 Table des matières (docs/)

### 📘 Architecture & Gouvernance
- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) — Vue d’ensemble logique, physique et sécurité.  
- [GOVERNANCE.md](./docs/GOVERNANCE.md) — Structure décisionnelle et RACI.  
- [BUSINESS.md](./docs/BUSINESS.md) — Alignement stratégique et valeur d’affaires.  

### 🔐 Sécurité, Risque & Conformité
- [SECURITY.md](./docs/SECURITY.md) — Contrôles techniques et défenses en profondeur.  
- [RISK_MANAGEMENT.md](./docs/RISK_MANAGEMENT.md) — Méthodologie et matrice de risques.  
- [COMPLIANCE.md](./docs/COMPLIANCE.md) — Cycle de conformité et mappage normatif.  
- [AUDIT.md](./docs/AUDIT.md) — Processus d’audit, collecte des preuves et restitution.  

### ⚙️ Implémentation & Opérations
- [IMPLEMENTATION.md](./docs/IMPLEMENTATION.md) — Déploiement, configuration, automatisation.  
- [OPERATIONS.md](./docs/OPERATIONS.md) — Exploitation quotidienne, supervision et PRA.  

### 🧩 Composants principaux
- [IIQ.md](./docs/IIQ.md) — Gouvernance des identités et workflows.  
- [CYBERARK.md](./docs/CYBERARK.md) — Gestion des comptes à privilèges.  
- [CyberArk-PVWA-API.md](./docs/CyberArk-PVWA-API.md) — Référence API PVWA et intégrations Ansible.  
- [ENTRA.md](./docs/ENTRA.md) — Gestion des identités cloud et PIM.  
- [DEVELOPERS.md](./docs/DEVELOPERS.md) — Guide de développement et pipelines CI/CD.  

### 💬 Support & Référence
- [FAQ.md](./docs/FAQ.md) — Questions fréquentes.  
- [GLOSSARY.md](./docs/GLOSSARY.md) — Définitions et acronymes utilisés.

---

## 🔄 Cycle de vie : de la gouvernance à la preuve

Chaque document et chaque automatisation du dépôt s’inscrivent dans un **cycle continu** :

> **Définir → Implémenter → Surveiller → Auditer → Améliorer**

1. **Définir** : la gouvernance fixe les règles, politiques et rôles (GOVERNANCE, BUSINESS).  
2. **Implémenter** : les composants techniques (IIQ, Entra, CyberArk, Ansible) appliquent ces règles (IMPLEMENTATION).  
3. **Surveiller** : les opérations et le SOC mesurent la performance (OPERATIONS, SECURITY).  
4. **Auditer** : la conformité et les contrôles sont vérifiés (AUDIT, COMPLIANCE).  
5. **Améliorer** : les risques sont réévalués et les politiques ajustées (RISK_MANAGEMENT).

Ce modèle fait de la conformité et de la sécurité **un processus itératif**, non un état statique.

---

## 🧠 Références normatives

| Réf. | Cadre / Norme | Domaine |
|------|----------------|---------|
| [1] | **NIST SP 800-53 rev5** | Contrôles de sécurité et de confidentialité |
| [2] | **NIST SP 800-207** | Zero Trust Architecture |
| [3] | **ISO/IEC 27001:2022** | Système de management de la sécurité |
| [4] | **CIS Controls v8** | Hygiène de cybersécurité |
| [5] | **MITRE ATT&CK** | Cartographie des tactiques et techniques |
| [6] | **Microsoft EAM** | Tiering et séparation des privilèges |
| [7] | **ITIL v4** | Gouvernance et amélioration continue |
| [8] | **SOC 2 Type II** | Contrôles de confiance et d’assurance |

---

## 🤝 Contribution et maintenance

Ce dépôt est conçu comme un **référentiel vivant**.  
Les contributions suivent le cycle CI/CD documenté dans [DEVELOPERS.md](./docs/DEVELOPERS.md) et les règles de gouvernance décrites dans [GOVERNANCE.md](./docs/GOVERNANCE.md).

**Principes de contribution** :
1. Respecter le modèle de tiering : aucun code T1/T2 ne peut interagir avec le T0.  
2. Soumettre toute modification via Pull Request signée (GPG ou HMAC).  
3. Inclure la documentation associée dans `/docs/`.  
4. Référencer les normes ou contrôles concernés.  
5. Soumettre aux revues croisées : *Architecture / Sécurité / GRC*.

Les validations finales sont assurées par le **Comité GRC-Sécurité**.

---

## 🧩 À propos

Ce projet incarne la **fusion entre technique, gouvernance et conformité**.  
Il démontre qu’une architecture d’identité bien conçue peut être à la fois **sécurisée, automatisée et économiquement efficiente**, tout en restant alignée sur les cadres normatifs internationaux.

> “La confiance se construit dans la transparence, se mesure dans la traçabilité et se maintient dans l’amélioration continue.”


### 🧩 Référence Tiering
- [TIERING_MATRIX.md](./docs/TIERING_MATRIX.md) — Classification EAM (T0/T1/T2) et diagrammes.
