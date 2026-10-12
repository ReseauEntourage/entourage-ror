---
name: perf-check
description: Revue de performance d'une branche d'entourage-ror. N+1 dans les listes et serializers, coût des requêtes (jointures, index, PostGIS, timeouts), cache (Rails.cache, Redis), dénormalisations (compteurs, jobs denorm, observers), jobs Sidekiq. À utiliser pour « N+1 », « c'est lent », « performance », « preload », « cache », « dénormaliser », « compteur », « timeout », « EXPLAIN », ou avant un merge qui touche des requêtes.
argument-hint: "[base, par défaut origin/master]"
---

# Revue de performance

Périmètre et format des constats : `.claude/skills/delivery-report/findings-format.md`. Préfixe des constats : `P-`.

Règle d'or : pas de gain annoncé sans mesure (nombre de requêtes avant/après, ou durée `EXPLAIN ANALYZE`). Sans mesure, le constat dit « probable » et indique comment mesurer.

## Les contraintes de la prod

| Limite | Valeur | Où |
|---|---|---|
| `statement_timeout` des requêtes web | 2 s par défaut | `config/database.yml` (`ACTIVERECORD_STATEMENT_TIMEOUT`) |
| Timeout de requête HTTP | `RACK_TIMEOUT` (5 s par défaut, 10 s en prod) | `config/initializers/rack_timeout.rb` |
| Phase de release (migrations) | 90 s | `Procfile*` |
| Threads Puma / pool DB | `MAX_THREADS` (10 par défaut) / `MAX_THREADS` (5 par défaut) | `config/puma.rb`, `config/database.yml` |
| `per` d'une liste API | plafonné à 50 dans `Api::V1::BaseController#per` | certains contrôleurs le redéfinissent sans plafond |

Ordres de grandeur en prod (sept. 2026) : `chat_messages` 3,5 M lignes (3,3 Go), `neighborhoods_entourages` 25 K lignes, environ 270 groupes publics actifs. Les bases locale et de préprod sont minuscules : une requête rapide en local ne prouve rien.

## 1. N+1

**Où regarder** : toute action qui rend une collection (`.page().per()`, `each_serializer`, `ActiveModel::Serializer::CollectionSerializer`), et tout serializer utilisé dans une liste, même s'il a été écrit pour un objet seul.

**Anti-patterns déjà rencontrés dans le dépôt** :

- `object.members.pluck(...)`, `object.member_ids.include?(...)`, `Xxx.where(...).exists?` ou `.where(...).first` dans un serializer : une requête par enregistrement.
- `image_url_with_size` : une requête `ImageResizeAction` par image.
- Valeur dépendant de l'utilisateur courant (statut d'adhésion, non-lus, `following`) calculée par enregistrement.
- `includes(user: :user_badges, user: :partner)` : clé de hash dupliquée, la première est perdue sans erreur. Écrire `includes(user: [:user_badges, :partner])`.
- `pluck(:id)` puis `where(id: ...)` : deux requêtes là où un sous-select suffit.

**Corrections, dans l'ordre de préférence** :

1. `includes` / `preload` pour une association simple.
2. Un preloader du dépôt (`app/services/preloaders/*.rb`) : une requête groupée pour la page, résultat posé sur chaque enregistrement (`preloaded_*`, clé par id utilisateur si la valeur dépend de l'utilisateur), lecture avec repli sur la requête unitaire. Exemple : `Preloaders::Outing.preload_member_ids` lu par `object.preload_member_ids || object.member_ids` dans `app/serializers/v1/outings/index_serializer.rb`. Appeler le preloader dans le contrôleur, après la pagination.
3. `lazy_relationship` (ams_lazy_relationships / BatchLoader) déjà utilisé par `ConversationSerializer`, `EntourageSerializer`, `SmalltalkSerializer`. Attention : sur master, `BatchLoader::Middleware` n'est pas monté, donc le cache BatchLoader n'est jamais vidé entre deux requêtes d'un même thread. Le correctif (608d3b1c6) est sur staging via `n-1-exploration`.

Pour mémoriser une valeur qui peut être `nil` ou `false`, tester `instance_variable_defined?` plutôt que `||=`.

**Prouver l'absence de N+1** :

- Si `spec/support/n_plus_one_helper.rb` existe sur la base de la branche (`git ls-files spec/support/n_plus_one_helper.rb`), écrire la spec dans `spec/n_plus_one/<chemin du contrôleur>_spec.rb` :

  ```ruby
  it_behaves_like 'an endpoint without N+1 queries' do
    def populate(count) = count.times { create :outing, :outing_class, user: create(:public_user), participants: [create(:public_user)] }
    def perform_request = get :index, params: { token: user.token }
    def returned_items_count = JSON.parse(response.body)['outings'].size
  end
  ```

  `populate` doit créer des enregistrements aux associations **distinctes** (le cache SQL masque les doublons). `pending: 'raison'` marque un N+1 connu. `N_PLUS_ONE_VERBOSE=1` affiche les comptes.
- Sinon, compter les requêtes à 1 puis à N éléments :

  ```ruby
  def count_queries(&block)
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] unless payload[:name].in?(%w[SCHEMA CACHE]) || payload[:cached] }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &block)
    queries
  end
  ```

  Le nombre de requêtes ne doit pas croître avec N.
- En développement, Bullet est actif (`DISABLE_BULLET=true` pour le couper) et signale dans les logs.

## 2. Coût des requêtes

- **Jointures qui multiplient les lignes** : joindre deux `has_many` (liens d'évènements × messages récents) avant un `count(distinct)` explose. Préférer des sous-requêtes corrélées ou un `EXISTS`. Cas réel : `Neighborhood.order_by_activity`, passé de 5,6 s (p95) à 40 ms.
- **COUNT sur grosse table** dans une requête web (back-office compris) : risque de `statement timeout`. Index adapté, compteur dénormalisé, ou affichage dégradé si la requête est annulée.
- **Index** : une nouvelle condition `where` ou un nouvel `order` sur une grosse table a-t-il un index utilisable ? Vérifier dans les migrations (`db/schema.rb` n'est pas fiable). La création d'index relève de `migration-check`.
- **Géographie** : les index GiST de `entourages`, `neighborhoods` et `user_smalltalks` portent sur l'expression `st_setsrid(st_makepoint(longitude, latitude), 4326)`. Un prédicat qui ne reprend pas exactement cette expression (`ST_Transform(..., 3857)`, `ST_Distance(...) < x`, bounding box sur `latitude`/`longitude`) ne peut pas l'utiliser. Préférer `ST_DWithin` sur l'expression indexée.
- **Pagination** : `OFFSET` profond coûteux ; une pagination par curseur existe déjà (`FeedServices::OutingsFinder`, `starting_after`).
- **Boucles** : `find_each` / `in_batches` sur les tables volumineuses, `update_all` / `insert_all` plutôt qu'un `save` par ligne (en sachant que ces méthodes sautent callbacks et observers).
- **Mesurer** : `EXPLAIN (ANALYZE, BUFFERS)` en préprod pour l'exactitude, et en prod en lecture seule uniquement avec l'accord de la personne. La procédure est dans `.claude/skills/datadog-investigation/SKILL.md`, section « Mesurer une requête lente ».

## 3. Cache

- `Rails.cache` n'est pas configuré en production : le store par défaut est local au dyno et non partagé. Ne pas compter sur lui pour un cache commun ; Rack::Attack l'utilise, donc ses compteurs sont par dyno.
- Redis direct (`$redis`, `config/initializers/redis.rb`) : POI (`app/services/poi_services/poi_optimized_serializer.rb`), stats publiques, géocodage approché. Pour toute nouvelle clé :
  - TTL explicite (`setex`) ;
  - clé versionnée et invalidée à la modification de la donnée source ;
  - **identifiant de l'utilisateur dans la clé** si la valeur dépend de lui (sinon fuite de données, voir `security-check`) ;
  - jamais `$redis.keys(...)` (parcours de tout le keyspace, bloquant) : utiliser `scan_each` ou des clés connues.
- Pas de cache HTTP (`fresh_when`, `stale?`) dans l'API aujourd'hui : en proposer un seulement si la réponse ne dépend pas de l'utilisateur.

## 4. Dénormalisation

**Existant** (il n'y a aucun `counter_cache:` Rails) :

| Valeur | Maintenue par |
|---|---|
| `number_of_people`, `number_of_confirmed_people` (entourages, neighborhoods, smalltalks) | `JoinableScopable#members_has_changed!`, appelé par `JoinRequestObserver` ; contrôle/correction : `rake db:check:number_of_people`, `rake db:fix:number_of_people` |
| `users.entourages_count`, `actions_count`, `outings_count`, `neighborhoods_count` | `UserStatsJob` (UPDATE atomique), mis en file par `JoinRequestObserver` ; reprise : `rake db:backfill:stats_counters` |
| `join_requests.unread_messages_count` | `UnreadChatMessageJob`, mis en file par `DenormChatMessageObserver` (`after_commit`) |
| `number_of_root_chat_messages` | `CountChatMessageJob`, même observer |
| `chat_messages.comments_count` | `ChatMessage#update_parent_comments_count` (`after_commit`, UPDATE atomique) |
| `conversation_message_broadcasts.sent_recipients_count` | `update_counters` + `ConversationMessageBroadcastDenormJob` (file `denorm`) |
| `entourage_denorms` | `EntourageDenormObserver` (`app/models/entourage_denorm_observer.rb`) |
| vue matérialisée `engagement_levels` | `RefreshEngagementLevelsJob`, sidekiq-cron à 2 h |

**Avant d'ajouter ou de modifier une valeur dénormalisée**, vérifier chaque point :

1. **Tous les chemins d'écriture** la mettent à jour : création, changement de statut, suppression, actions du back-office, rake tasks. `update_all`, `delete_all`, `update_column` et les imports sautent callbacks et observers.
2. **Mise à jour atomique** en SQL (`UPDATE … SET x = (SELECT count(*) …)`, `update_counters`), jamais lire-incrémenter-écrire en Ruby.
3. **`after_commit`**, pas `after_save` : sinon le job peut tourner avant que la donnée soit visible.
4. **Job idempotent et dédoublonné** : recalcul complet plutôt qu'incrément, et `sidekiq_options lock: :until_executed, lock_args: ->(args) { args }, on_conflict: :reschedule` comme `UnreadChatMessageJob`. La file doit être consommée en prod (voir `quality-check`).
5. **Reprise** : une rake task de backfill (`lib/tasks/`), plus une tâche de contrôle si la valeur peut dériver.
6. **Spec** : la valeur est juste après chaque chemin d'écriture.
7. **Sémantique** : la valeur dénormalisée doit dire la même chose que le calcul qu'elle remplace. Exemple ouvert : les non-lus comptés par `EntourageSerializer` (tous les messages) diffèrent de `JoinRequest#unread_messages_count` (messages racines actifs). Changer de source change les chiffres affichés : décision produit.

## 5. Jobs

- Concurrence en prod (app back-office) : `worker_1` 2 threads (sms, salesforce), `worker_2` 2 threads (translation, mailers, default, openai_requests, broadcast, denorm). Un job lent ou massif retarde toute sa file.
- Un job déclenché par un callback très fréquent (chaque message, chaque join_request) doit être dédoublonné ou regroupé.
- Les boucles d'envoi (push, mails) traitent par lots (`find_in_batches(batch_size: 100)`).

## 6. Rendu

Constats `P-NN` au format commun, avec la mesure quand elle existe (« 3 → 3 requêtes pour 1 → 4 éléments », « 40 ms en prod »), puis la ligne de statut du thème.
