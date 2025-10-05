# DEVELOPERS – Guide de développement et intégration

## 1. Objectif
Fournir un cadre commun pour les développeurs travaillant sur les pipelines **GitHub Actions**, les playbooks **Ansible** et les intégrations **API IIQ / CyberArk / Entra ID**.

## 2. Bonnes pratiques générales
- Respect du modèle **Infrastructure as Code**.  
- Code signé (HMAC / commit signé GPG).  
- Respect du **tiering** : aucun script T1/T2 ne s’exécute sur des ressources T0.  
- Respect des politiques de sécurité CI/CD (GitHub branch protection).  

## 3. Structure recommandée
```
/playbooks/
   ├── t2_standard/
   ├── t1_admin/
   └── t0_bastion/
/actions/
   ├── build.yml
   ├── deploy.yml
   └── audit.yml
```

## 4. Exemples
### 4.1 Appel API signé HMAC (Python)
```python
import hmac, hashlib, base64

secret = b'my_shared_secret'
message = b'POST:/api/v1/accounts'
signature = base64.b64encode(hmac.new(secret, message, hashlib.sha256).digest())
print(signature.decode())
```

### 4.2 Playbook Ansible (demande JIT admin)
```yaml
- name: Request T1 JIT Access via PVWA API
  uri:
    url: "{{ PVWA_BASE_URL }}/PasswordVault/API/Accounts/{{ account_id }}/Requests"
    method: POST
    headers:
      Authorization: "Bearer {{ PVWA_TOKEN }}"
  register: result
```

## 5. Pipelines CI/CD
Chaque commit sur `main` déclenche :
1. L’analyse de sécurité (CodeQL / SAST).  
2. L’audit de conformité (lint + tests).  
3. La génération des rapports (`/reports/automation/`).  

## 6. Références
- DevSecOps NIST SP 800-204C  
- CIS Control 16 (Application Security)  
- GitHub Security Best Practices
