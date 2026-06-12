# Design Spec — Skills Product & Design pour Entourage

**Date :** 2026-03-18
**Auteur :** CPO Entourage
**Statut :** Approuvé

---

## Contexte

Le CPO de l'association Entourage souhaite alimenter Claude en skills métier pour son quotidien produit. Entourage est une association dont les produits visent à mobiliser l'engagement citoyen en faveur des personnes en situation de précarité. Les contraintes sont celles d'une ONG : budget limité, peu de développeurs, pas d'objectifs commerciaux.

---

## Objectif

Créer 3 skills Claude Code + 1 fichier contexte partagé (à créer dans le cadre de ce projet), couvrant les 6 use cases du CPO :

| Use case | Skill | Mode |
| --- | --- | --- |
| 1. Écriture de PRD | `product-craft` | PRD |
| 2. Rédaction de user stories | `product-craft` | User Story |
| 3. Création de designs | `design-partner` | Création |
| 4. Design reviews | `design-partner` | Review |
| 5. Stratégie produit | `product-strategy` | Stratégie / Priorisation |
| 6. Supports de communication produit | `product-strategy` | Comms |

---

## Architecture

### Arborescence

```
~/.claude/skills/
├── entourage-context.md          ← contexte partagé, à créer (voir ci-dessous)
├── product-craft/
│   └── SKILL.md
├── design-partner/
│   └── SKILL.md
└── product-strategy/
    └── SKILL.md
```

### Principe transversal

Chaque skill commence par lire `~/.claude/skills/entourage-context.md` avant toute action.
Tous les skills fonctionnent en **mode mixte** : challenge sur les décisions clés d'abord, puis livrable structuré.

---

## Fichier `entourage-context.md` (à créer)

Ce fichier est en scope du projet. Contenu minimum requis par section :

```markdown
# Entourage — Contexte Produit

## Mission
Mobiliser l'engagement citoyen en faveur des personnes en situation de précarité.

## Produits
- App mobile Entourage : crée du lien entre citoyens de proximité et personnes en situation de rue
  (dire bonjour, offrir un café, aider avec des démarches admin, etc.)
- [Autres produits à compléter]

## Personas
- Citoyen engagé : riverain ou passant qui souhaite s'impliquer localement
- Personne en situation de rue : bénéficiaire principal, souvent peu lettré numériquement
- Travailleur social : professionnel de l'accompagnement, utilisateur avancé
- Partenaire associatif : organisation alliée, usage backoffice / reporting

## Principes produit
- Impact social avant croissance des métriques
- Accessibilité renforcée (public vulnérable, fracture numérique)
- Éthique des données (personnes vulnérables)
- Non-commercial : pas de publicité, pas de monétisation directe

## Contraintes
- Budget limité (ONG)
- Équipe dev réduite
- Recours aux bénévoles pour certaines contributions

## Métriques de succès
- Engagement citoyen (actions réalisées, personnes impliquées)
- Mobilisation (nouveaux engagés, récurrence)
- Impact mesurable sur les personnes en précarité
- PAS de métriques commerciales (revenus, conversion payante, LTV)
```

---

## Skill 1 — `product-craft`

**Triggers :** "PRD", "spec cette feature", "user story", "critères d'acceptation", "rédige une spec"

**Comportement mode mixte :**
1. Challenge d'abord — 3 à 4 questions ciblées :
  - Quel problème utilisateur ça résout ? Pour quel persona ?
  - Quel impact attendu sur l'engagement ou la mission ?
  - Contrainte technique ou effort estimé ?
  - C'est must-have ou nice-to-have par rapport à la mission ?
2. Puis production du livrable selon le type demandé

**Format PRD Entourage :**
```
# PRD — [Nom de la feature]

## Problème utilisateur
[Description du problème, du contexte, de la fréquence]

## Personas concernés
[Quel(s) persona(s) sont impactés et comment]

## Impact attendu
[Sur l'engagement, la mobilisation ou la mission — pas de métriques commerciales]

## Solution proposée
[Description fonctionnelle de la feature]

## Critères d'acceptation
- [ ] ...
- [ ] ...

## Hors périmètre
[Ce que cette feature ne fait pas]

## Contraintes & dépendances
[Technique, légal, partenaires, ressources dev]

## Métriques de succès
[Indicateurs non-commerciaux mesurables]
```

**Format User Story Entourage :**
```
En tant que [persona],
Je veux [action],
Afin de [impact sur la mission / bénéfice réel].

Critères d'acceptation :
- [ ] ...
- [ ] ...
```

---

## Skill 2 — `design-partner`

**Triggers :** "crée un design", "maquette", "review ce design", "critique cette UI", "améliore cet écran"

### Détection automatique du mode

| Signal d'entrée | Mode activé |
| --- | --- |
| L'utilisateur fournit une image, une capture d'écran, ou un lien Figma | Review |
| L'utilisateur décrit un écran à créer (texte uniquement) | Création |
| Ambiguïté (ex: "travaille sur cet écran") | Claude demande : "Tu veux qu'on crée quelque chose de nouveau ou qu'on review l'existant ?" |

### Mode création

1. Challenge — 3 questions :
  - Quel écran, pour quel persona ?
  - Quel moment du parcours utilisateur ?
  - Contrainte technique ou de plateforme particulière ?
2. Si le skill `bencium-innovative-ux-designer` est disponible dans `~/.claude/skills/`, l'invoquer pour la génération UI.
  - `bencium-innovative-ux-designer` est un skill de génération d'interfaces installé localement, spécialisé dans la création d'UI production-grade avec une forte attention au design.
  - Invocation : `Use skill bencium-innovative-ux-designer`
3. Contraintes Entourage à transmettre au skill : accessibilité renforcée, clarté avant originalité, mobile-first, public potentiellement peu lettré numériquement

### Mode review

1. Challenge — 2 questions :
  - Quel est l'objectif de cet écran ?
  - Qu'est-ce qui te questionne ou te dérange ?
2. Critique structurée en 4 axes :

```
## Design Review — [Nom de l'écran]

### Clarté & lisibilité
[Évaluation pour le public cible Entourage]

### Accessibilité
[Vulnérabilité, fracture numérique, taille des éléments, contraste]

### Cohérence avec la mission
[Ton, valeurs, absence de logique commerciale]

### Faisabilité technique
[Réalisme par rapport aux contraintes dev Entourage]

### Recommandations prioritaires
1. [Impact fort] ...
2. [Impact moyen] ...
3. [Impact moindre] ...
```

---

## Skill 3 — `product-strategy`

**Triggers :** "priorise", "roadmap", "stratégie produit", "slide", "présentation", "conseil d'admin", "OKR"

### Mode priorisation

**Framework adapté ONG :**

```
Score = (Impact mission × Portée personas) / Effort dev
```

**Barème (échelle 1–5 pour chaque variable) :**

| Variable | 1 | 3 | 5 |
| --- | --- | --- | --- |
| Impact mission | Marginal, indirect | Contribue clairement | Critique pour la mission |
| Portée personas | 1 persona, rare | 2 personas, fréquent | Tous les personas, quotidien |
| Effort dev | Plusieurs mois | Quelques sprints | 1–2 jours |

Challenge préalable — 2 questions :
- Quelles features sont en compétition ?
- Quelle est la contrainte principale du moment (temps, devs, budget) ?

### Mode stratégie

1. Challenge — 2 questions :
  - Horizon de temps (3 mois, 1 an, 3 ans) ?
  - Décision à prendre ou cap à fixer ?
2. Produit : synthèse des options avec leurs implications sur la mission, les ressources, et l'impact
3. Question finale systématique : *"Quelle option est la plus fidèle à la mission d'Entourage ?"*

### Mode comms

**Pour qui → quel livrable :**

| Audience | Format |
| --- | --- |
| Équipe produit / dev | Roadmap technique (features, sprints, dépendances) |
| Conseil d'administration | Synthèse impact + décisions clés (1 page ou 5 slides max) |
| Partenaires / donateurs | Narrative d'impact (résultats, prochaines étapes, besoin) |
| Grand public / bénévoles | Message simple, chiffres d'impact, appel à l'action |

Challenge préalable — 2 questions :
- Pour quelle audience ?
- Quel est le message principal qui doit rester après la présentation ?

Règles communes : données d'impact en avant, pas de jargon technique, pas de métriques commerciales.

---

## Critères de succès (vérifiables)

- [ ] Chaque skill lit `entourage-context.md` en première instruction
- [ ] Chaque skill pose ses questions de challenge avant tout livrable (3–4 pour product-craft, 2–3 pour design-partner et product-strategy)
- [ ] Aucun livrable ne contient de section "revenus", "conversion", "LTV" ou autre métrique commerciale
- [ ] Chaque PRD contient une section "Impact attendu" et une section "Métriques de succès" non-commerciales
- [ ] Le skill design-partner détecte correctement le mode (création vs review) selon les règles définies
- [ ] Le skill product-strategy utilise le barème 1–5 pour la priorisation

---

## Hors périmètre

- Skills de développement technique (couverts par Superpowers)
- Skills marketing ou fundraising
- Automatisation ou scripts Python
- Versioning des skills (géré manuellement pour l'instant)

---

## Étapes d'implémentation

1. Créer et remplir `~/.claude/skills/entourage-context.md` avec le CPO
2. Créer `~/.claude/skills/product-craft/SKILL.md`
3. Créer `~/.claude/skills/design-partner/SKILL.md`
4. Créer `~/.claude/skills/product-strategy/SKILL.md`
