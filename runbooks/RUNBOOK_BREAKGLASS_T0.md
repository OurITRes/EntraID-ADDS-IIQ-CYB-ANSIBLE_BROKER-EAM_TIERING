# Runbook — Break-Glass T0

## Objectif
Permettre la continuité d’activité si PVWA/PSM est indisponible **tout en maîtrisant le risque**.

## Conditions de déclenchement
- Incident P1 confirmé (PSM/PVWA indisponible, changement critique requis).
- Autorisation du CISO ou délégué + ticket d’incident.

## Étapes
1. **Activer coffre break-glass** hors-ligne (HSM/Sealed, 2-of-3 signataires).
2. **Ouvrir bastion T0** en mode restreint (journalisation, vidéo).
3. **Activer compte d’urgence** (durée ≤ 30 min) via script signé.
4. Effectuer l’action minimale requise.
5. **Désactiver** le compte d’urgence + rotation secrets.
6. **Post-mortem** : rapport détaillé (horodatage, personnes, commandes).

## Contrôles
- MFA matériel, réseau isolé, interdiction d’Internet.
- Journalisation immuable (WORM) + témoin papier si requis.
