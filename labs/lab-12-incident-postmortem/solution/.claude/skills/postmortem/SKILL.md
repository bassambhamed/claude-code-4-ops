---
name: postmortem
description: Rédige un post-mortem blameless après un incident de production, à partir d'une timeline, de logs et de l'historique de déploiement. Produit un document structuré avec cause racine, impact quantifié, MTTD/MTTR et actions correctives assignées. À utiliser après le rétablissement du service.
---

# Skill : postmortem

Objectif : transformer un incident en **apprentissage exploitable**, pas en compte rendu
qu'on archive sans le lire.

## Quand l'utiliser

Après le rétablissement du service, une fois la timeline et les preuves collectées
(voir le sous-agent `incident-analyst`).

## Structure imposée

1. **Résumé** — trois lignes : impact utilisateur, durée, cause en une phrase.
2. **Chronologie** — tableau horodaté : détection, diagnostic, actions, rétablissement.
   Indiquer la source de chaque horodatage (alerte, log, commit, message).
3. **Impact quantifié** — durée d'indisponibilité, services affectés, requêtes en échec,
   utilisateurs concernés. Des chiffres, pas des adjectifs.
4. **Cause racine** — clairement distinguée des **facteurs aggravants**. Une seule cause
   racine ; si plusieurs semblent en lice, dire laquelle est retenue et pourquoi.
5. **Ce qui a fonctionné / ce qui a manqué** — détection, outillage, documentation,
   communication.
6. **Actions correctives** — tableau : action | propriétaire | échéance | critère de clôture.
   Séparer les actions **immédiates** (rétablissement) des actions **de fond** (récurrence).
7. **Indicateurs** — MTTD (détection) et MTTR (rétablissement), avec la méthode de calcul.

## Garde-fous

- **Blameless** : aucun nom de personne, aucune formulation de responsabilité individuelle.
  Les causes sont systémiques — un processus qui permet l'erreur humaine est la cause.
- Aucune donnée client, aucun secret, aucune adresse interne dans le document.
- **Aucune action corrective sans propriétaire ni échéance.** Une action sans propriétaire
  est une intention, pas une action : ne pas l'inscrire.
- Ne pas conclure sur une cause racine non étayée : « cause indéterminée, investigation en
  cours » est une conclusion acceptable.

## Sortie

Un fichier `docs/postmortems/AAAA-MM-JJ-<titre-court>.md`, prêt à être relu en revue d'équipe.
