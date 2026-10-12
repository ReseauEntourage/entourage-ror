---
name: branch-review
description: Revue complète d'une branche d'entourage-ror avant merge. Lance en parallèle les contrôles sécurité, performance, qualité, testabilité, données personnelles, compatibilité apps et migrations, vérifie les constats, puis publie le rapport de livraison unifié.
argument-hint: "[branche ou base, par défaut la branche courante contre origin/master]"
disable-model-invocation: true
---

# Revue complète de branche

Cible : $ARGUMENTS (par défaut : la branche courante, diff `origin/master...HEAD`).

Ce skill orchestre les skills `*-check` du dépôt et finit par `delivery-report`. Chaque contrôle rend ses constats au format de `.claude/skills/delivery-report/findings-format.md`.

## 1. Cadrer

```bash
git fetch origin master --quiet
git branch --show-current
git log --reverse --format='%h %s' origin/master..HEAD
git diff --stat origin/master...HEAD
git status --short
```

- Ticket : le préfixe `EN-xxxx` du nom de branche ou des commits.
- S'il reste des changements non commités, le dire et les inclure dans le périmètre.
- Si la branche est vide par rapport à master, s'arrêter et le dire.

## 2. Trier les thèmes

Tous les thèmes figurent dans le rapport. Un thème que le diff ne touche pas est marqué `Sans objet` avec la raison, sans lancer son contrôle.

| Thème | Skill | Lancer si le diff touche… |
|---|---|---|
| Sécurité | `security-check` | contrôleurs, routes, serializers, params, requêtes SQL, auth, webhooks, uploads, config |
| Performance | `perf-check` | requêtes, scopes, serializers, contrôleurs de liste, jobs, callbacks, observers, migrations d'index |
| Qualité | `quality-check` | tout code Ruby (toujours lancé s'il y a du Ruby) |
| Testabilité | `testability-check` | tout code applicatif (toujours lancé s'il y a du code dans `app/` ou `lib/`) |
| Données personnelles | `rgpd-check` | modèle `User` ou colonnes de données personnelles, serializers d'utilisateurs, exports, logs, intégrations externes (Salesforce, Mailjet, OpenAI, Slack) |
| Compatibilité apps | `api-compat-check` | `app/controllers/api/`, serializers, `config/routes.rb`, validations de modèles exposés à l'API, `metadata` |
| Migrations | `migration-check` | `db/migrate/`, `lib/tasks/` de reprise de données |

## 3. Lancer les contrôles en parallèle

Un sous-agent `general-purpose` par thème retenu, tous dans le même message. Chaque consigne contient :

- le périmètre exact (branche, base, liste des fichiers du diff) ;
- « Charge le skill `<nom>` avec l'outil Skill et applique-le à ce périmètre » ;
- « Ne modifie aucun fichier, ne commite rien » ;
- « Rends uniquement les constats au format de `.claude/skills/delivery-report/findings-format.md`, puis la ligne de statut du thème ».

Pendant ce temps, lancer soi-même les specs touchées par la branche (voir `testability-check` pour la commande) afin d'avoir le résultat pour la section « Comment tester ».

## 4. Vérifier avant de rapporter

- Relire soi-même dans le code chaque constat `Bloquant` ou `Important` : le scénario doit tenir. Sinon, le rétrograder ou l'écarter.
- Dédoublonner : un même défaut vu par deux thèmes garde le thème le plus pertinent et cite l'autre.
- Séparer ce qui est introduit par la branche de ce qui est préexistant.

## 5. Rendre

1. Résumé dans le terminal : un tableau thème / statut / nombre de constats, puis les constats `Bloquant` et `Important` en clair.
2. Charger le skill `delivery-report` et publier (ou mettre à jour) le rapport de la branche avec ces constats dans la section « Contrôles ».
3. Proposer de corriger les constats, un commit par correctif. Ne rien corriger sans accord.
