# Synthèse exécutive

En 2025, l’entreprise franchit une étape décisive dans la modernisation de son infrastructure identitaire.  
Face à l’augmentation de la complexité des environnements hybrides — mêlant Azure, AWS, Entra ID et forêts Active Directory multiples — la gouvernance des identités devient le socle de la résilience numérique et de la sécurité d’entreprise.

Ce projet, intitulé **EntraID-ADDS-IIQ-CYB-ANSIBLE_BROKER-EAM_TIERING_v1.0**, établit une fondation unifiée et automatisée de l’identité. Il s’appuie sur **SailPoint IIQ** comme moteur de gouvernance, **Entra ID** comme pivot cloud, **CyberArk** comme coffre et broker d’accès privilégié, et **Ansible/GitHub Actions** comme orchestrateur d’automatisation sécurisée.  
L’ensemble adopte le modèle **EAM (Enterprise Access Model)** de Microsoft et les principes **Zero Trust** [1][2].

La transformation vise trois résultats majeurs :
1. **Une seule licence par utilisateur**, même en présence de plusieurs forêts ADDS ;
2. **Une disparition du standing access** au profit d’un accès éphémère et justifié (JIT/PIM) ;
3. **Une automatisation auditable et traçable de bout en bout**, de la demande d’accès jusqu’à la clôture de session.

Cette architecture ne se limite pas à la rationalisation technique ; elle réinvente la chaîne de confiance entre l’identité, les accès et les environnements critiques.  
Elle permet d’unifier la gestion, de renforcer la posture de sécurité, et d’optimiser les coûts tout en respectant les standards internationaux (NIST, CIS, ISO/IEC, MITRE ATT&CK) [3][4][5][6][7].

---

# 1. Contexte et vision stratégique

## 1.1 Contexte
L’entreprise opérait jusqu’à présent plusieurs forêts Active Directory isolées, supportant des environnements hybrides et multicloud.  
Cette fragmentation induisait des coûts élevés, des silos de gestion et une surface d’attaque accrue.

La multiplication des identités synchronisées entre forêts, combinée à la duplication de licences Microsoft 365, entraînait une **inefficience opérationnelle** et un **risque accru de compromission des privilèges**.

## 1.2 Vision stratégique
La stratégie adoptée consiste à replacer l’identité comme **pierre angulaire du modèle de sécurité**.  
Le projet vise à construire une identité unique par individu, capable de traverser plusieurs forêts ADDS sans coût supplémentaire, tout en maintenant une gouvernance centralisée et une sécurité de niveau Tier 0 à Tier 2 [2].

Cette trajectoire est alignée sur :
- Les **principes Zero Trust** : ne jamais faire confiance par défaut, vérifier systématiquement chaque accès [1] ;
- Le **modèle EAM (Enterprise Access Model)** : segmentation des privilèges par tiers de sécurité [2] ;
- Le **concept Secure-by-Design** : intégration des contrôles dès la conception [3].

---

# 2. Objectifs de la transformation

## 2.1 Objectifs principaux
1. **Unifier la gouvernance des identités** à travers SailPoint IIQ et Entra ID.
2. **Éliminer le standing access**, en favorisant les accès JIT (Just-In-Time) via PIM et CyberArk.
3. **Réduire les coûts de licences** en adoptant un modèle d’identité unique.
4. **Automatiser les processus de provisioning et de révocation** grâce à Ansible et GitHub Actions.
5. **Garantir la traçabilité et la conformité** aux cadres normatifs internationaux [3][6][7].

## 2.2 Objectifs secondaires
- Accélérer la délégation administrative via les **Administrative Units** d’Entra ID.
- Séparer les responsabilités par tiers (T0/T1/T2).
- Renforcer la supervision et la détection des anomalies via Splunk et Grafana.
- Mettre en place une gouvernance continue des privilèges (Identity Security Posture Management).

---

# 3. Modèle de valeur d’affaires : “Une licence, plusieurs forêts”

## 3.1 Principe de mutualisation des licences
Traditionnellement, chaque compte présent dans une forêt synchronisée vers Entra ID consommait une licence distincte.  
Le modèle proposé rompt avec cette logique en introduisant un **pivot identitaire unique** : l’objet Entra ID devient la représentation principale de l’utilisateur, tandis que les comptes ADDS secondaires sont liés par extensionAttribute (10/11/12).

Ce modèle repose sur :
- Le **SCIM connector** entre IIQ et Entra ID ;
- Le **Graph API** pour enrichir les attributs étendus ;
- La synchronisation Entra Connect configurée en **mode “single anchor”** ;
- L’usage d’un **orchestrateur (Ansible/GitHub Actions)** qui déclenche la création des comptes ADDS non licenciés mais rattachés à l’objet principal.

## 3.2 Impact économique
- **Réduction moyenne de 25 à 40 %** du coût des licences Microsoft 365.  
- **Simplification des audits** et de la gestion contractuelle.
- **Rationalisation du modèle d’identité** dans le SOC et le SIEM.
- **Réduction du shadow IT** par suppression des comptes orphelins.

## 3.3 Gains immatériels
- Meilleure expérience utilisateur (une seule identité).
- Simplification de la gestion du cycle de vie (IIQ).
- Renforcement de la cohérence entre sécurité et productivité.

---

# 4. Bénéfices techniques, opérationnels et sécuritaires

## 4.1 Bénéfices techniques
- Architecture modulaire, codée en Infrastructure-as-Code (Terraform, Ansible).
- Provisionnement automatisé via IIQ → Orchestrateur → CyberArk → Entra ID/ADDS.
- Zéro dépendance manuelle : tout est traçable, auditable, reproductible.
- Simplification du modèle DNS/DHCP via Infoblox délégué.

## 4.2 Bénéfices opérationnels
- Réduction du temps de déploiement des comptes de 70 %.
- Uniformisation des processus de création, modification et suppression.
- Meilleure agilité lors des fusions/acquisitions.
- Réduction des délais de réponse aux incidents.

## 4.3 Bénéfices sécuritaires
- Élimination du standing access via PIM + CyberArk (JIT).
- Sessions isolées et monitorées via PSM et JEA.
- Application stricte du principe du moindre privilège.
- Alignement avec les contrôles AC-2, AC-6, IA-2 et AU-12 du NIST SP 800-53 [3].

---

# 5. Indicateurs de performance (KPI)

| Indicateur | Objectif cible | Mode de mesure |
|-------------|----------------|----------------|
| **Taux de comptes avec standing access** | < 5 % | CyberArk reports + PIM logs |
| **Durée moyenne d’activation PIM** | < 15 min | PIM audit + IIQ workflow |
| **Réduction du nombre de licences 365** | > 30 % | Billing reports + Entra ID |
| **Taux de conformité des privilèges** | > 95 % | IIQ certification campaigns |
| **Taux de provisioning automatisé** | > 90 % | Ansible job reports |
| **Taux d’audit réussi sans dérogation** | 100 % | Audit interne / externe |
| **MTTR sur incident identitaire** | < 2 h | SOC / Splunk metrics |

---

# 6. Alignement stratégique et conformité

## 6.1 Cadres de référence
Cette architecture s’appuie sur plusieurs cadres normatifs complémentaires :
- NIST SP 800-53 rev5 (contrôles AC, IA, AU) [3]
- NIST SP 800-207 (Zero Trust Architecture) [1]
- CIS Controls v8 (contrôles 5, 6, 16) [4]
- MITRE ATT&CK (techniques d’escalade et persistance) [5]
- ISO/IEC 27001:2022 (SGSI) [6]
- NIST CSF 2.0 (fonctions stratégiques) [7]

## 6.2 Alignement des piliers d’architecture et du NIST CSF 2.0

| Pilier d’architecture | Identify | Protect | Detect | Respond | Recover |
|------------------------|-----------|----------|----------|-----------|-----------|
| **Zero Trust** | Classification des identités et actifs | Authentification forte et vérification continue | Détection d’accès anormal | MFA adaptatif | Isolation segmentée |
| **Secure-by-Design** | Cartographie et design défensif | Durcissement OS, LAPS, PPL | SIEM et logs centralisés | Plans d’incident | Restauration maîtrisée |
| **EAM (Tiering)** | Rôles et périmètres T0/T1/T2 | Isolation des privilèges | Détection de mouvements latéraux | Révocation ciblée | Reconfiguration rapide |
| **PAW** | Attribution par niveau | Poste sécurisé et cloisonné | Détection des dérives d’usage | Session cloisonnée | Reset automatisé |

---

# 7. Conclusion et perspectives

La valeur du programme **EntraID-ADDS-IIQ-CYB-ANSIBLE_BROKER-EAM_TIERING_v1.0** réside dans sa capacité à unir la rigueur de la gouvernance et la souplesse de l’automatisation.  
Il définit un modèle durable où chaque identité est gérée, chaque accès justifié et chaque action journalisée.  
La maîtrise du risque devient mesurable, la conformité vérifiable, et la sécurité intégrée au quotidien des opérations.

Cette transformation positionne l’entreprise dans une trajectoire d’excellence opérationnelle, alignée sur les cadres internationaux et prête pour les futures exigences de cybersécurité.

---

# Annexe A — Références normatives

| Réf. | Norme / Cadre | Description synthétique |
|------|----------------|--------------------------|
| [1] | **NIST SP 800-207** | Zero Trust Architecture — segmentation et vérification continue. |
| [2] | **Microsoft EAM (Enterprise Access Model)** | Modèle de tiering T0–T2 pour la maîtrise des privilèges. |
| [3] | **NIST SP 800-53 rev5** | Contrôles de sécurité (AC, IA, AU) pour la gouvernance des accès. |
| [4] | **CIS Controls v8** | Bonnes pratiques pour l’administration sécurisée d’Active Directory. |
| [5] | **MITRE ATT&CK** | Techniques d’escalade et de persistance dans les environnements Windows. |
| [6] | **ISO/IEC 27001:2022** | Système de gestion de la sécurité de l’information (SGSI). |
| [7] | **NIST Cybersecurity Framework 2.0** | Fonctions Identify–Protect–Detect–Respond–Recover. |
