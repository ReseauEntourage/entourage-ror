---
name: migration-check
description: Vérifier qu'une migration ou une reprise de données d'entourage-ror passe sans risque en production (phase de release Heroku à 90 s, tables volumineuses, index concurrents, backfills, suppression ou renommage de colonnes, lecteurs externes de la base). À utiliser pour « migration », « ajouter une colonne / un index », « backfill », « rake de reprise », « db/migrate », ou avant un merge qui touche le schéma.
argument-hint: "[fichier de migration, ou base par défaut origin/master]"
---

# Migrations et reprises de données sûres

Périmètre et format des constats : `.claude/skills/delivery-report/findings-format.md`. Préfixe des constats : `M-`.

## Comment les migrations partent en production

- Chaque `Procfile*` (api et back-office, prod et préprod) lance `release: ACTIVERECORD_STATEMENT_TIMEOUT=90s bundle exec rake db:migrate`. Les migrations tournent **automatiquement à chaque déploiement**, avant le redémarrage des dynos, avec un `statement_timeout` de 90 s.
- Pendant la release, l'ancien code tourne encore. Une migration doit donc être compatible avec le code d'avant **et** celui d'après.
- La CI rejoue toutes les migrations depuis une base vide (`db:drop db:create db:migrate`) : une migration doit tourner sur une base vide.
- `db/schema.rb` ne se charge pas (erreur de syntaxe depuis ea128a10d) et n'est pas à jour. Ne jamais s'y fier pour connaître le schéma réel : lire les migrations. Après `db:migrate` en local, regarder `git diff db/schema.rb` et ne commiter que les lignes de la migration ; si le dump réécrit tout le fichier, le signaler au lieu de le commiter tel quel.
- D'autres lecteurs utilisent la même base : les Lambdas de `entourage-tasks` (statistiques, engagement, Salesforce, notifications in-app), Metabase, les tables `stats.*`. Avant de renommer ou supprimer une colonne ou une table : `grep -rn "<nom>" ../entourage-tasks --include=*.py --include=*.js --include=*.ts --include=*.sql`.

Tables volumineuses ou très écrites : `chat_messages` (plusieurs Go), `users`, `join_requests`, `entourages`, `user_reactions`, `translations`, `inapp_notifications`, `rpush_notifications`, `session_histories`, `login_histories`, `email_deliveries`, `sms_deliveries`, `user_applications`. Sur ces tables, toute opération qui verrouille ou réécrit la table est un constat.

## Les cas courants

| Opération | Façon sûre |
|---|---|
| Ajouter une colonne | Nullable, ou avec un défaut **constant** (instantané sur PostgreSQL 16). Pas de défaut volatil (`now()`, `gen_random_uuid()`) sur une grosse table. |
| Ajouter un index sur une grosse table | `disable_ddl_transaction!` + `add_index ..., algorithm: :concurrently, if_not_exists: true`, précédé d'un `DROP INDEX CONCURRENTLY IF EXISTS` pour nettoyer un index invalide laissé par une tentative interrompue, et un timeout étendu le temps de la construction. Modèle : `db/migrate/20260907120000_add_last_message_index_to_chat_messages.rb` (helper `with_extended_statement_timeout`). Sans `concurrently`, l'écriture dans la table est bloquée pendant toute la construction. |
| Supprimer un index | `remove_index ..., algorithm: :concurrently, if_exists: true` avec `disable_ddl_transaction!`. |
| Contrainte `NOT NULL` sur une colonne existante | `add_check_constraint ..., validate: false`, puis validation dans une migration séparée. |
| Clé étrangère sur une grosse table | `add_foreign_key ..., validate: false`, puis `validate_foreign_key` séparément. |
| Supprimer une colonne | Deux déploiements : d'abord `self.ignored_columns += ["colonne"]` et plus aucune lecture dans le code (ni dans `entourage-tasks`), puis la suppression. Sinon l'ancien code plante entre la release et le redémarrage. |
| Renommer une colonne ou une table | Jamais directement : ajouter la nouvelle, écrire dans les deux, reprendre les données, basculer les lectures, supprimer l'ancienne. |
| Changer le type d'une colonne | Réécrit la table sous verrou exclusif : passer par une nouvelle colonne. |
| Valeur d'enum PostgreSQL | `execute "ALTER TYPE ... ADD VALUE IF NOT EXISTS ..."` avec `disable_ddl_transaction!` (modèle `20260611120700_add_welcome_unseen_event.rb`). |
| Colonne utilisée par une vue | Recréer la vue dans la même migration (vue `chat_message_reactions`, vue matérialisée `engagement_levels` : modèle `20260908120000_...`). |

## Reprises de données

- **Pas de reprise dans la migration** dès que la table est grosse : elle tourne sous le timeout de 90 s et bloque le déploiement. Séparer : la migration ajoute le schéma, une rake task fait la reprise. Modèle : `20260723093622_add_stats_counters_to_users.rb` + `lib/tasks/stats_counters.rake` (`rake db:backfill:stats_counters`).
- La rake task est **idempotente** (relançable sans effet de bord), traite par lots (`in_batches`, `find_each`) ou en SQL ensembliste, et affiche sa progression.
- Pas d'appel à une API externe ligne par ligne dans une migration (géocodage, Salesforce) : passer par des jobs.
- Ne pas utiliser les modèles applicatifs dans une migration (ils évoluent et cassent le rejeu en CI) : SQL, ou une classe locale `Class.new(ActiveRecord::Base) { self.table_name = '...' }`.
- La reprise se lance après le déploiement, à la main : `heroku run -a <app> bundle exec rake ...`. La commande et sa durée estimée vont dans la section « Déploiement » du rapport.

## Données JSON des entourages

`metadata` est validé par un JSON schema (`Entourage.json_schema`, `JsonSchemaService.base`) qui interdit les clés inconnues et **rend toutes les clés obligatoires**. Ajouter une clé sans valeur par défaut (`before_validation :set_outings_<clé>` dans `app/models/entourage.rb`) rend invalides les sorties existantes à leur prochaine mise à jour. Modèle : les commits EN-9582 `00d2c19c0` et `333fec310`.

## Vérifier

```bash
# Comme la CI : rejouer depuis une base vide
RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
# Réversibilité, en local
bundle exec rake db:migrate && bundle exec rake db:rollback STEP=<n> && bundle exec rake db:migrate
```

- Taille réelle d'une table : en préprod, ou en prod en lecture seule avec l'accord de la personne (procédure dans `.claude/skills/datadog-investigation/SKILL.md`) :
  `SELECT pg_size_pretty(pg_total_relation_size('chat_messages')), reltuples::bigint FROM pg_class WHERE relname = 'chat_messages';`
- Version de migration : `ActiveRecord::Migration[7.1]`.
- Méthode `change` réversible, ou `up` / `down` explicites.

## Rendu

Constats `M-NN` au format commun, la ligne de statut du thème, et pour le rapport : la liste des migrations, si elles tiennent dans la release, les reprises à lancer après déploiement (commande exacte), et l'ordre de déploiement si plusieurs étapes sont nécessaires.
