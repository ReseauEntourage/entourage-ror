---
name: datadog-investigation
description: Enquêter sur des erreurs ou lenteurs de production d'entourage-ror à partir des logs Datadog (lograge, router Heroku, Postgres), puis corriger un commit par cause. À utiliser quand on parle de 500, timeouts, erreurs en prod, logs Datadog, Rack::Attack / 429, requêtes lentes, statement timeout, ou « qu'est-ce qui casse en prod ».
argument-hint: "[période ou endpoint, ex. 'derniers 7 jours' ou 'POST /api/v1/user_smalltalks']"
---

# Enquête sur les logs Datadog

Cible : $ARGUMENTS (par défaut, les erreurs des 15 derniers jours).

## Ce qu'il faut savoir avant de chercher

- Datadog EU : https://app.datadoghq.eu, service `service:entourage-back-prod`. Rétention 15 jours, pas d'archive : une analyse ne remonte jamais plus loin.
- On y accède par le navigateur (skill `claude-in-chrome`). Il n'y a pas d'API Datadog configurée.
- **Angles morts** :
  - Le back-office (`admin.entourage.social`, app Heroku `local-backoffice-prod`) n'a pas de log drain : ses logs applicatifs sont absents. Ses requêtes SQL apparaissent quand même dans les logs Postgres.
  - Les logs des jobs Sidekiq sont absents. Leurs erreurs SQL se voient dans les logs Postgres (`application_name` contient `sidekiq`).
- **Bruit** : environ 98 % des logs `status:error` viennent de l'agent Datadog (autodiscovery Postgres, `sql_error_code:42501`). Toujours exclure `-@sql_error_code:42501`, ou partir des lignes lograge.

## Les sources de logs

| Source | Ce qu'on y trouve | Comment la filtrer |
|---|---|---|
| Lograge (une ligne JSON par requête Rails) | contrôleur, action, statut, durée, `request_id` | Le JSON n'est **pas** parsé : passer par un champ calculé grok (ci-dessous) |
| Lignes Rails du même `request_id` | exception et backtrace | Rechercher le `request_id` trouvé dans la ligne lograge |
| Router Heroku | toutes les requêtes, y compris celles refusées avant Rails (429 de Rack::Attack, timeouts H12) | `heroku/router` ; attention, l'URL complète y figure, `token=` compris |
| Postgres | `sql_error_code`, `application_name` (puma, sidekiq, Metabase, psql), statement timeouts | `@sql_error_code:57014` pour les timeouts |

## Méthode

1. **Regrouper les 500 par contrôleur et action** avec un champ calculé grok sur `message`, puis une table groupée par `#ctrl` / `#act` :

   ```
   %{data}"controller":"%{regex("[A-Za-z0-9:]+"):ctrl}","action":"%{regex("[A-Za-z0-9_]+"):act}","status":500%{data}
   ```

   Pour toutes les requêtes (taux d'appel d'une route), retirer `,"status":500`.
2. **Pour chaque groupe**, ouvrir un exemple, récupérer le `request_id`, retrouver l'exception et la ligne de code dans les lignes Rails.
3. **Regrouper par cause**, pas par endpoint : une même cause peut toucher plusieurs routes.
4. **Qualifier chaque cause** : volume sur la période, impact utilisateur réel, risque du correctif. Une erreur sans 500 peut être plus grave (une fonction silencieusement cassée, un mail jamais envoyé).
5. **Classer** du meilleur rapport impact/effort au moins bon. Les correctifs rapides et sûrs d'abord.
6. **Corriger un commit par cause**, chacun avec une spec qui échoue sans le correctif (skill `testability-check`). Les causes risquées, externes (Salesforce, Soliguide, Redis) ou sans impact sont laissées de côté, avec la raison.
7. **Rapport** : skill `delivery-report`, type « Investigation ». Section 1 = causes corrigées (avec la signature de l'erreur), section 5 = laissé de côté et pourquoi.

## Pièges de l'interface Datadog

- Le tableau des logs ne s'affiche qu'après avoir fait défiler la page.
- Les regroupements à 3 niveaux et les regex du type `[^\"]` peuvent figer l'onglet. Rester à 2 niveaux et utiliser `%{data}`.
- Passer le champ calculé dans l'URL du Log Explorer plutôt que de modifier les pipelines : on ne touche pas à la configuration partagée.
- Rack::Attack répond avant Rails, donc sans ligne lograge : les 429 se comptent sur les lignes du router. Pour reconstituer les fenêtres fixes de 5 minutes par IP, extraire les minutes de `@timestamp` par grok (`:x0-4` / `:x5-9`).

## Mesurer une requête lente

- **Préproduction** (`entourage-back-preprod`, base externe sans add-on Heroku) : `heroku run -a entourage-back-preprod bin/rails runner '...'`. Le script doit refuser de tourner si la base courante est celle de prod (`daki09gqhvij3b`). La base de préprod est petite : elle sert à vérifier que les résultats sont identiques, pas à mesurer.
- **Production** : uniquement avec l'accord explicite de la personne, et seulement en lecture.
  - Toujours `BEGIN READ ONLY;` puis `SET LOCAL statement_timeout = '30s';` (la session lecture seule n'impose ni l'un ni l'autre).
  - `EXPLAIN (ANALYZE, BUFFERS)` seulement pour la nouvelle requête. L'ancienne, lente, se contente d'un `EXPLAIN` sans exécution.
  - Ne jamais afficher l'URL de connexion ni de données personnelles : seulement des volumes et des durées.
- Comparer à ce que Datadog mesure pour l'endpoint (p95), pas au coût estimé du planner : ce coût sert à comparer des plans, pas deux requêtes.

## Après la mise en production

Pour chaque correctif, noter dans le rapport (section « Déploiement », ligne « Après la mise en prod ») le signal à vérifier : disparition de l'erreur, baisse du p95, disparition des statement timeouts sur la table.
