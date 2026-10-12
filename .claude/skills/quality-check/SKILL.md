---
name: quality-check
description: Contrôle qualité du code d'une branche d'entourage-ror. Rubocop limité aux lignes modifiées, respect des conventions du dépôt (services builder + callback, observers, jobs Sidekiq, serializers V1), code mort, duplication, lisibilité, messages de commit. À utiliser pour « qualité du code », « relis mon code », « rubocop », « c'est propre ? », ou avant un merge.
argument-hint: "[base, par défaut origin/master]"
---

# Contrôle qualité du code

Périmètre et format des constats : `.claude/skills/delivery-report/findings-format.md`. Préfixe des constats : `Q-`.

La référence est le code qui entoure le changement : un nouveau code doit se lire comme ses voisins (nommage, densité de commentaires, idiomes). Une règle rubocop qui contredit le style du fichier n'est pas un constat.

## 1. Rubocop sur les lignes modifiées

Rubocop ne tourne pas en CI et le code existant viole beaucoup de règles de `.rubocop.yml`. Ne regarder que les lignes de la branche :

```bash
ruby .claude/skills/quality-check/rubocop_diff.rb            # base origin/master
ruby .claude/skills/quality-check/rubocop_diff.rb staging    # autre base
```

Trier la sortie :

| À remonter | À ignorer si le fichier fait pareil |
|---|---|
| `Lint/*` (variables inutilisées, `rescue` qui avale tout, conditions toujours vraies) | `Style/MethodCallWithArgsParentheses` (l'existant écrit `create :pro_user`, `validates :x`) |
| `Security/*` | `RSpec/BeEq`, `RSpec/NestedGroups`, `RSpec/MultipleMemoizedHelpers`, `RSpec/ContextWording`, `RSpec/NamedSubject` |
| `Rails/*` : `Rails/TimeZone`, `Rails/Date`, `Rails/SkipsModelValidations`, `Rails/WhereExists`… | `Style/*` purement de forme, quand le fichier suit une autre convention |
| `Performance/*` | `Layout/*` dans un fichier qui a déjà le même écart |

Ne jamais lancer `rubocop -a` sur un fichier entier : cela réécrit du code hors de la branche.

## 2. Conventions du dépôt

Vérifier que le nouveau code suit les patterns existants plutôt que d'en inventer un :

- **Services** : `app/services/<domaine>_services/`, modules `XxxServices::`. Le pattern dominant est le builder avec callback : `XxxBuilder.new(params:, user:).create { |on| on.success { … }; on.failure { … } }` (base `app/services/callback.rb`, exemple `app/services/entourage_services/outing_builder.rb`). Pas de `.call` à inventer si le domaine utilise déjà un builder.
- **Asynchrone** : `AsyncService.new(Klass).methode(args)` (`app/services/async_service.rb`) pour déporter un appel de classe, ou un job dédié.
- **Jobs** : majoritairement des workers Sidekiq (`include Sidekiq::Worker`, `sidekiq_options queue: :xxx`), certains exposent un `self.perform_later`. Vérifier que :
  - la file est consommée en production : Sidekiq tourne sur l'app back-office, donc la file doit figurer dans `Procfile.backoffice-prod` et `Procfile.backoffice-preprod` (aujourd'hui `sms`, `salesforce`, `translation`, `mailers`, `default`, `openai_requests`, `broadcast`, `denorm`), et dans `Procfile` pour le dev. Une file absente n'est jamais consommée, sans erreur ;
  - les arguments sont des types JSON simples (ids, chaînes), jamais un objet ou une `ActiveRecord::Relation` (un `deliver_later` avec une Relation a cassé l'invitation papotages pendant des mois sans erreur visible).
- **Observers** (`app/observers/`, déclarés dans `config/application.rb`) : effets de bord seulement, encapsulés dans un `rescue` pour ne jamais faire échouer l'action principale. Un nouvel effet de bord caché dans un observer ou un callback doit être signalé : il surprend les specs et les lecteurs (EN-9673 : la notification Slack géocodait à la création).
- **Évènements** : `PublishesEvents` + `EventBus` + `app/subscribers/` pour les réactions découplées (badges).
- **Serializers** : `app/serializers/v1/`, ActiveModelSerializers 0.10 avec `AmsLazyRelationships`. Une valeur calculée par enregistrement relève de `perf-check`.
- **Erreurs d'API** : réutiliser le format d'erreur existant du contrôleur (`render json: { message:, reasons: }` ou `lib/api/v1/api_error.rb` selon le voisinage) plutôt qu'un nouveau format. Les messages destinés à l'utilisateur passent par i18n avec `user.lang`.
- **Exceptions** : un `rescue` doit soit gérer le cas, soit le remonter à Sentry (`Sentry.capture_exception`). Un `rescue => e` silencieux est un constat.
- **Temps** : `Time.zone.now` / `Time.current`, pas `Time.now` ni `Date.today` (fuseau Paris).
- **Booléens venant des params** : vérifier le cast. `ActiveModel::Type::Boolean` transforme toute valeur hors `false/f/0/off` en `true` (`"abc"` → `true`), ce qui rend une validation `inclusion` inopérante.

## 3. Lecture du diff

Pour chaque fichier modifié, chercher :

- **Duplication** : une méthode, un scope ou un helper existant fait déjà la même chose (`grep` sur le nom du concept avant de conclure).
- **Code mort** : méthode, route, colonne ou branche de `case` devenue inutile après le changement ; code commenté laissé en place.
- **Nommage** : noms métier du dépôt (outing, neighborhood, smalltalk, join_request, entourage pour les actions). Un nom qui ment sur ce que fait la méthode est un constat.
- **Taille et responsabilité** : contrôleur qui porte de la logique métier déplaçable dans un service ou un modèle ; méthode qui mélange requête, règles et formatage.
- **Cohérence** : même règle implémentée deux fois avec des résultats différents (ex. deux règles de rôle modérateur qui divergent).
- **Commentaires** : expliquent le pourquoi, au même niveau de densité que le fichier ; pas de commentaire qui paraphrase le code ou qui raconte l'historique du changement.

## 4. Commits

- Sujet : `EN-xxxx <zone>: <ce qui change, en minuscules>` (ou `<zone>: …` sans ticket), en anglais. Corps en anglais qui explique le pourquoi.
- Un commit par changement logique ; pas de commit « fix typo » à garder en l'état avant merge (proposer un fixup, sans réécrire l'historique sans accord).
- Aucun fichier parasite : `.env*`, dumps, `tmp/`, `log/`, `.irb_history`, fichiers de données (`*.csv`, `users.csv`).

```bash
git log --format='%h %s' origin/master..HEAD
git diff --name-only origin/master...HEAD
```

## 5. Rendu

Constats `Q-NN` au format commun, puis la ligne de statut du thème. Les écarts rubocop de forme se résument en une seule `Note` (« N écarts de style, conformes au style du fichier »), sans les lister un par un.
