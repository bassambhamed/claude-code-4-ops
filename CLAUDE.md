# CLAUDE.md — dépôt de formation « Claude Code pour les Ops »

Contexte destiné à Claude Code lorsqu'il travaille **sur ce dépôt de formation**
(pas sur l'application fil rouge, qui a son propre `CLAUDE.md` une fois `/init` exécuté).

## Nature du dépôt

Dépôt de **contenu pédagogique**, pas une codebase applicative. Il contient :
- `modules/` — 10 modules sur les briques de Claude Code (théorie courte + mini-lab) ;
- `labs/` — 12 labs Ops + un capstone, chacun avec son corrigé dans `solution/` ;
- `plugins/oddo-ops-toolkit/` — le plugin d'équipe construit pendant la formation ;
- `ecommerce-app/` — l'application fil rouge (.NET Aspire), **livrée nue** ;
- `slides/` — PDF uniquement (sources LaTeX dans `../Ops_Claude_code_latex/`).

## Règles de contenu

- **Langue : français.** Code, identifiants, extraits de configuration et sorties de commandes en anglais.
- **Public : Ops / DevOps / SRE débutants sur Claude Code.** Expliquer le *pourquoi* avant le *comment* ;
  jamais de jargon non défini ; pas de pré-requis en développement applicatif.
- **Public bancaire (DORA, RGPD).** Chaque lab doit énoncer ses garde-fous. Aucune action destructive
  ou prod ne doit apparaître sans validation humaine explicite.
- **Canevas imposé des labs** : Objectif · Pré-requis · Briques mobilisées · Déroulé pas-à-pas ·
  Livrable · Garde-fous · Pour aller plus loin.
- **Canevas imposé des modules** : La limite qu'on vient de rencontrer · Le concept · Anatomie ·
  Mini-lab · Erreurs fréquentes · Checklist de sortie.

## Invariants à ne pas casser

- `ecommerce-app/` reste **sans `.claude/`, sans Dockerfile, sans manifests, sans CI** : c'est ce que
  les participants produisent. Tout artefact généré va dans `labs/lab-NN-*/solution/`.
- La **progression des briques est volontaire** : commandes natives → contexte → commandes perso →
  skills → hooks → MCP → plugins → sous-agents → automatisation. Ne pas réordonner sans demande.
- Les modules **06 (MCP)** et **07 (plugins)** présentent d'abord les éléments **officiels**
  (marketplace `claude-plugins-official`, serveurs MCP publics) **puis** la personnalisation interne.
- `slides/` ne contient **que des PDF**. Aucun `.tex`, `.aux`, `.log` ici.

## Vérifier l'application fil rouge

```bash
export PATH="/usr/local/share/dotnet:$PATH"
cd ecommerce-app
dotnet build ECommerce.slnx
dotnet run --project src/ECommerce.AppHost
```

## Compiler les slides

Les sources sont **hors de ce dépôt**, dans `../Ops_Claude_code_latex/` :

```bash
cd ../Ops_Claude_code_latex && make all      # compile et copie les PDF dans Ops_Claude_code/slides/
```

Conventions LaTeX (pièges déjà rencontrés) : thème autonome sans police externe, frames avec
`lstlisting` en `[fragile]`, accents gérés par `\lstset{literate=...}`, schémas TikZ larges enveloppés
dans `\resizebox`, pas d'emoji ni de caractères de dessin de boîte. Détail dans le `README.md` du
dossier LaTeX.
