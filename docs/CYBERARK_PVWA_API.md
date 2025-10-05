# CyberArk PVWA API – Référence et exemples d’intégration

> 💬 *“Security by automation, trust by verification.” — EAM Principle*

## 1️⃣ Contexte et rôle dans l’architecture

Le **Password Vault Web Access (PVWA)** est la **porte d’entrée sécurisée** des intégrations avec la plateforme CyberArk.  
Dans le modèle **Enterprise Access Model (EAM)**, c’est un **composant Tier 0 (control plane)**. Les appels en provenance de l’orchestrateur **Ansible / GitHub Actions (Tier 1)** traversent une **frontière contrôlée (broker)** pour joindre PVWA, sans jamais exposer le Vault directement au Tier 1.

Flux logique :
```
IIQ → Orchestrateur (Ansible) → PVWA API → Vault → PSM → Rotation → IIQ
```

Chaque appel est contrôlé, audité et enregistré.  
Aucun secret n’est manipulé directement par IIQ : seules des sessions temporaires Just-In-Time (JIT) sont établies.

---

## 2️⃣ Cycle d’intégration complet

1. **IIQ** initie une demande d’accès administrateur (T1/T0).  
2. **L’orchestrateur Ansible** relaie cette demande vers PVWA via API REST.  
3. **PVWA** valide la requête (MFA, justification, approbation).  
4. Une **session PSM** est ouverte, enregistrée et isolée.  
5. À la fermeture, **CyberArk effectue la rotation** du secret et notifie IIQ.  

---

## 3️⃣ Authentification (SSO SAML / OIDC)

Endpoint :  
```
POST /PasswordVault/API/Auth/SAML/Logon
```
Headers :
```http
Content-Type: application/json
Accept: application/json
```
Exemple de payload :
```json
{
  "SAMLResponse": "<token_SAML_base64>",
  "useRadiusAuthentication": false
}
```
Réponse (200 OK) :
```json
{
  "CyberArkLogonResult": "AAEAAWVy...",
  "Expiry": "2025-10-05T11:45:12Z"
}
```
Le jeton (`CyberArkLogonResult`) est ensuite utilisé dans le header :
```
Authorization: Bearer <token>
```

---

## 4️⃣ Demande d’accès JIT (T1 / T0)

Endpoint :  
```
POST /PasswordVault/API/Accounts/<id>/Requests
```
Payload :
```json
{
  "Reason": "Maintenance serveur SQL PRD",
  "Duration": 60,
  "TicketingSystem": "ServiceNow",
  "TicketID": "INC123456",
  "PlatformID": "WindowsDomain",
  "Safe": "T1-AdminAccounts",
  "AccessType": "PSM",
  "Labels": ["T1", "PAW-T1"],
  "Approvals": [
    {"Type": "Manager", "Value": "nicolas.lavoie"},
    {"Type": "Security", "Value": "grc.review"}
  ]
}
```
Réponse (200 OK) :
```json
{
  "RequestID": "REQ-2025-001245",
  "Status": "PendingApproval"
}
```

---

## 5️⃣ Démarrage de session PSM

Endpoint :
```
POST /PasswordVault/WebServices/PIMServices.svc/PSMConnect
```
Payload :
```json
{
  "UserName": "a-admin-t1",
  "ConnectionComponent": "RDP",
  "TargetSystem": "srv-sql-prd",
  "Record": true
}
```
Réponse :
```json
{
  "PSMConnectionID": "PSM-5678-XYZ",
  "Status": "Active"
}
```
La session est automatiquement enregistrée (vidéo et journal).  
L’événement est poussé dans `/vault/logs/psm_sessions.json`.

---

## 6️⃣ Fin de session et rotation

Endpoint :
```
POST /PasswordVault/API/Accounts/<id>/CheckIn
```
Puis :
```
POST /PasswordVault/API/Accounts/<id>/Change
```
Ces deux appels :
- clôturent la session,  
- déclenchent la rotation automatique du mot de passe,  
- mettent à jour le log d’audit (`rotation_status = completed`).

---

## 7️⃣ Exemple Python – Appel API JIT signé HMAC

```python
import hmac, hashlib, base64, requests, json

secret = b'my_shared_secret'
message = b'POST:/PasswordVault/API/Accounts/1234/Requests'
signature = base64.b64encode(hmac.new(secret, message, hashlib.sha256).digest())

headers = {
  "Authorization": "Bearer <token>",
  "Content-Type": "application/json",
  "X-HMAC-Signature": signature.decode()
}

payload = {
  "Reason": "Patch management",
  "Duration": 45,
  "Safe": "T0-PrivilegedAccounts",
  "Labels": ["T0", "PAW-T0"]
}

resp = requests.post("https://pvwa.corp.local/PasswordVault/API/Accounts/1234/Requests",
                     headers=headers, data=json.dumps(payload))
print(resp.status_code, resp.text)
```

---

## 8️⃣ Sécurité et conformité

> ⚠️ **Bonnes pratiques CyberArk PVWA API**

| Catégorie | Recommandation |
|------------|----------------|
| **Chiffrement** | Utiliser TLS 1.2+ avec certificats internes validés |
| **Secrets** | Jamais en clair dans le code / logs / collections Postman |
| **Authentification** | Jetons courts, rotation automatique |
| **Auditabilité** | Activer les journaux PSM + Vault rotation |
| **Orchestration** | Lancer les appels via Ansible ou GitHub Actions “non-T0” |
| **Traçabilité** | Tous les appels sont horodatés et corrélés dans Splunk |
| **Conformité** | Respecter NIST PR.AC-6 / CIS Control 5 / ISO 27001 A.9.4.3 |

---

## 9️⃣ Références normatives

| Réf. | Norme / Cadre | Domaine |
|------|----------------|---------|
| [1] | **NIST SP 800-53 rev5 – PR.AC-6** | Least Privilege |
| [2] | **ISO/IEC 27001:2022 – A.9.4.3** | Use of privileged utilities |
| [3] | **CIS Controls v8 – Control 5** | Account Management |
| [4] | **Microsoft EAM** | Tiering & Access Segmentation |
| [5] | **CyberArk API Guide (v13.x)** | REST API Reference |
