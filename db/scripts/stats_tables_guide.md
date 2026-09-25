# Guide des tables `stats.user_interactions`, `stats.user_profile` et `stats.user_interaction_pairs`

Ce document s'adresse aux personnes qui vont **exploiter** les données une
fois les scripts joués (analyse, clustering, construction d'un graphe
utilisateurs) — pas à celles qui génèrent/maintiennent les scripts SQL
(voir pour cela `user_interactions_prompt.md`, `user_profile_prompt.md` et
`user_interaction_pairs_prompt.md`, qui documentent les choix de
conception).

Les trois tables vivent dans le schéma `stats` (pas `public`) de la base
`entourage-back-preprod` :

| Table                        | Grain                          | Rafraîchissement | Généré par              |
|-------------------------------|---------------------------------|-------------------|--------------------------|
| `stats.user_profile`          | 1 ligne par utilisateur          | Snapshot complet (`TRUNCATE` + `INSERT`) | `user_profile.sql` |
| `stats.user_interactions`     | 1 ligne par événement/interaction | Recalculé section par section (`DELETE`+`INSERT` par `interaction_type`) | `user_interactions.sql` |
| `stats.user_interaction_pairs` | 1 ligne par paire d'utilisateurs en interaction, par contexte | Recalculé section par section (`DELETE`+`INSERT` par `interaction_type`, `ON CONFLICT DO UPDATE` en cas de recouvrement) | `user_interaction_pairs.sql` |

Pensées ensemble : `user_profile` donne les **nœuds** du graphe (qui est
l'utilisateur), `user_interactions` donne le **journal d'activité** par
utilisateur (ce qu'il a fait, avec qui/quoi, et quand), et
`user_interaction_pairs` donne directement les **arêtes** du graphe social
(quels utilisateurs ont réellement interagi entre eux) — voir le détail des
trois catégories d'interaction plus bas.

Pour récupérer un export CSV des tables (par exemple pour les
charger dans un notebook ou un outil de graphe hors base), voir
`export_stats_tables.sql` (même dossier) : à jouer avec le client
`psql` (`psql "<connexion>" -f db/scripts/export_stats_tables.sql`), il
génère `stats_user_profile.csv`, `stats_user_interactions.csv` et
`stats_user_interaction_pairs.csv` — le second couvre automatiquement
toutes les partitions par année de `stats.user_interactions`, une requête
sur la table parente suffit ; le troisième n'est pas partitionné, une
requête simple suffit aussi.

## ⚠️ À savoir avant d'interroger les données

- **Aucune des deux tables n'est un journal immuable.** Chaque exécution
  des scripts relit les tables sources de l'application (`users`,
  `chat_messages`, `join_requests`, ...) et régénère le contenu à partir
  de leur état courant. Si une donnée source a été supprimée ou modifiée
  entre deux exécutions (ex: un message passé en `status = 'deleted'`, un
  utilisateur supprimé), elle disparaît ou change dans `stats.*` au
  prochain run — ce ne sont donc pas des données figées dans le temps,
  même si `interaction_at` conserve la date d'origine de l'événement.
- **Pas de clé étrangère.** Les deux tables sont peuplées en SQL brut,
  sans contrainte `FOREIGN KEY` vers `users` ni entre elles. Le lien se
  fait uniquement par convention sur `user_id` (et `object_id` pour les
  interactions ciblant un autre utilisateur).
- Toutes deux sont préfixées par le schéma `stats` : penser à qualifier
  (`stats.user_profile`) ou faire un `SET search_path TO stats, public;`
  en session.
- **`stats.user_interactions` est partitionnée par année** sur
  `interaction_at` (une table physique `stats.user_interactions_<année>`
  par année, plus `stats.user_interactions_default` en secours). C'est
  totalement transparent pour vos requêtes : interroger
  `stats.user_interactions` normalement (`SELECT ... WHERE ...`) — pas
  besoin de cibler une partition en particulier. Cela ne devient utile à
  savoir que si vous inspectez le catalogue Postgres directement
  (`\d+ stats.user_interactions`) ou pour des requêtes très ciblées sur
  une seule année, où filtrer sur `interaction_at` permet à Postgres
  d'ignorer les autres partitions (*partition pruning*).
- **`stats.user_interaction_pairs` a un périmètre utilisateurs légèrement
  différent des deux autres tables** : elle exclut *tous* les comptes
  Entourage (`targeting_profile = 'team'`), alors que
  `stats.user_interactions`/`stats.user_profile` n'excluent que les
  modérateurs de l'équipe. Elle exclut aussi explicitement les paires
  d'utilisateurs qui se sont bloqués (dans un sens ou dans l'autre, à la
  date d'exécution du script — un blocage récent efface une interaction
  passée), et n'est pas partitionnée.

## `stats.user_profile` — un utilisateur = une ligne

| Colonne                    | Type      | Contenu |
|-----------------------------|-----------|---------|
| `user_id`                   | INTEGER (PK) | Identifiant utilisateur (`users.id`) |
| `user_type`                  | VARCHAR   | `pro` ou `public` |
| `goal`                        | VARCHAR   | Objectif déclaré (`offer_help`, `ask_for_help`, `organization`, `staff`, ou `NULL`) |
| `targeting_profile`            | VARCHAR   | Segmentation plus fine (`asks_for_help`, `offers_help`, `partner`, `team`, `ambassador`, ou `NULL`) — à croiser avec `goal` en cas d'ambiguïté |
| `validation_status`             | VARCHAR   | `validated`, `blocked`, `temporary_blocked`, `deleted`, `pending` |
| `deleted`                        | BOOLEAN   | Compte marqué supprimé côté application |
| `is_staff`                        | BOOLEAN   | `true` si admin, manager, super-admin ou rôle modérateur — à filtrer pour exclure les comptes internes d'un clustering utilisateurs |
| `partner_id`                       | INTEGER   | Organisation/partenaire de rattachement (surtout pour les comptes `pro`), `NULL` sinon |
| `country`                           | VARCHAR(2) | Code pays de l'adresse principale de l'utilisateur |
| `postal_code`                        | VARCHAR(8) | Code postal de l'adresse principale |
| `city`                                | VARCHAR    | Ville de l'adresse principale |
| `lang`                                 | VARCHAR    | Langue préférée (`fr` par défaut) |
| `age`                                   | INTEGER    | Calculé depuis `birthdate` ; `NULL` si non renseigné ou mal formé |
| `created_at`                             | TIMESTAMP  | Date d'inscription (ancienneté) |
| `last_sign_in_at`                         | TIMESTAMP  | Dernière connexion (récence), peut être `NULL` |
| `entourages_count`                         | INTEGER    | Nb total d'entourages (groupes+entraides+événements+conversations) créés |
| `actions_count`                              | INTEGER    | Nb d'entraides créées |
| `outings_count`                                | INTEGER    | Nb d'événements créés |
| `neighborhoods_count`                            | INTEGER    | Nb de quartiers créés |
| `willing_to_engage_locally`                        | BOOLEAN    | Disponibilité déclarée pour un engagement local |
| `travel_distance`                                    | INTEGER    | Distance de déplacement acceptée (km) |
| `availability`                                         | JSONB      | Disponibilités déclarées (créneaux), structure libre définie côté app |
| `interests`                                              | TEXT       | Centres d'intérêt (tags), **liste séparée par des virgules**, ex. `sport,lecture` |
| `involvements`                                             | TEXT       | Préférences de mode d'engagement (tags), même format |
| `concerns`                                                   | TEXT       | Catégories d'entraide qui intéressent l'utilisateur (tags), même format |
| `orientation`                                                  | VARCHAR    | Orientation déclarée, valeur unique (pas de virgules) |
| `badges`                                                         | TEXT       | Badges actifs obtenus, **liste séparée par des virgules**, ex. `first_action,ambassador` |

Colonnes volontairement absentes (voir `user_profile_prompt.md` pour le
détail) : aucune donnée directement identifiante (nom, email, téléphone),
pas d'adresse précise ni de coordonnées GPS, pas de `community` (retirée
sur demande).

## `stats.user_interactions` — un événement = une ligne

| Colonne             | Type       | Contenu |
|-----------------------|------------|---------|
| `id`                    | BIGSERIAL (PK) | Identifiant technique de la ligne |
| `user_id`                | INTEGER    | Utilisateur qui est à l'origine de l'interaction |
| `interaction_type`        | VARCHAR(40) | Type d'événement, voir table ci-dessous |
| `object_type`               | VARCHAR(40) | Catégorie de l'objet concerné, voir table ci-dessous |
| `object_id`                   | BIGINT     | Identifiant de l'objet concerné (son sens dépend de `object_type` ; peut être `NULL`, ex. pour une connexion) |
| `interaction_at`                | TIMESTAMP  | Date métier de l'événement (pas toujours `created_at` — voir colonne "Date" ci-dessous) |
| `description`                     | TEXT       | Texte libre, format variable selon `interaction_type` (souvent des fragments `clé=valeur`) — non structuré, à parser au cas par cas si besoin |

### Types d'interaction (`interaction_type`)

| `interaction_type`             | `object_type`                | Table source | Date utilisée | Ce que ça représente |
|----------------------------------|-------------------------------|---------------|-----------------|------------------------|
| `connexion`                        | `Session`                      | `login_histories` | `connected_at` | Une connexion (≈1 ligne/heure/utilisateur) |
| `session`                            | `Session`                      | `session_histories` | `date` | Une session applicative (1 ligne/jour/plateforme) |
| `creation_groupe`                      | `Groupe`                       | `entourages` (`group_type='group'`) | `created_at` | Création d'un groupe communautaire |
| `creation_entraide`                      | `Entraide`                     | `entourages` (`group_type='action'`) | `created_at` | Création d'une entraide |
| `creation_evenement`                       | `Evenement`                    | `entourages` (`group_type='outing'`) | `created_at` | Création d'un événement |
| `creation_conversation`                      | `Conversation`                  | `entourages` (`group_type='conversation'`) | `created_at` | Création d'une conversation privée |
| `creation_quartier`                            | `Quartier`                      | `neighborhoods` | `created_at` | Création d'un quartier |
| `demande_adhesion`                               | `Groupe`/`Evenement`/`Conversation`/`Quartier`/`Bonnes ondes` | `join_requests` (`accepted_at` NULL) | `requested_at` ou `created_at` | Demande pour rejoindre (hors entraide), non acceptée |
| `demande_adhesion_entraide`                        | `Entraide`                       | `join_requests` (`group_type='action'`, `accepted_at` NULL) | idem | Demande pour rejoindre une entraide, non acceptée |
| `adhesion_confirmee`                                 | idem que `demande_adhesion`        | `join_requests` (`accepted_at` non nul) | `accepted_at` | Adhésion confirmée (hors entraide) |
| `adhesion_confirmee_entraide`                          | `Entraide`                         | idem, `group_type='action'` | `accepted_at` | Adhésion confirmée à une entraide |
| `participation_evenement`                                | `Evenement`                        | `join_requests` (`participate_at` non nul) | `participate_at` | Participation confirmée à un événement |
| `message_envoye`                                           | `Conversation`/`Evenement`/`Quartier`/`Bonnes ondes` | `chat_messages` | `created_at` | Message envoyé (hors groupe/entraide) |
| `publication_groupe`                                         | `Groupe`                            | `chat_messages` (`group_type IN ('group','action')`) | `created_at` | Message posté dans un groupe ou une entraide |
| `reaction`                                                     | `Message`                            | `user_reactions` | `created_at` | Réaction sur un message (`description` = clé de la réaction) |
| `blocage_utilisateur`                                            | `Utilisateur`                          | `user_blocked_users` | `created_at` | `object_id` = utilisateur bloqué |
| `invitation_envoyee`                                               | `Utilisateur`                            | `entourage_invitations` | `created_at` | `object_id` = utilisateur invité ; `description` contient l'entourage concerné |
| `suivi_partenaire`                                                   | `Partenaire`                              | `followings` | `created_at` | Suivi d'un partenaire |
| `demande_partenariat`                                                  | `Partenaire`                                | `partner_join_requests` | `created_at` | Demande de partenariat |
| `inscription_bonnes_ondes`                                               | `Bonnes ondes`                                | `user_smalltalks` | `created_at` | Inscription au dispositif bonnes ondes |
| `match_bonnes_ondes`                                                       | `Bonnes ondes`                                  | `user_smalltalks` (`matched_at` non nul) | `matched_at` | Mise en relation obtenue |
| `reponse_sondage`                                                            | `Message`                                        | `survey_responses` | `created_at` | Réponse à un sondage (`object_id` = message contenant le sondage) |
| `badge_obtenu`                                                                 | `Badge`                                            | `user_badges` (`active`) | `awarded_at` ou `created_at` | Badge obtenu (`description` = tag du badge) |
| `notification_recue`                                                             | variable (voir note ⚠️)                              | `inapp_notifications` | `created_at` | Notification reçue ; `description` contient l'expéditeur si connu |
| `visionnage_contenu_pedago`                                                        | `Contenu pédago`                                       | `users_resources` (`watched=true`) | `updated_at` | Ressource pédagogique visionnée ; `description` contient nom/catégorie/tag |

⚠️ **`notification_recue` est un cas particulier** : son `object_type`
n'est pas une valeur fixe de la liste ci-dessus mais reprend directement
le nom de classe Rails de l'objet notifié (`inapp_notifications.instance`
ou `instance_baseclass`), donc potentiellement toute classe du modèle
(`Entourage`, `ChatMessage`, `User`...). À traiter séparément si besoin
d'une catégorisation homogène.

## `stats.user_interaction_pairs` — une paire d'utilisateurs en interaction = une ligne

Contrairement à `stats.user_interactions` (journal d'activité **par
utilisateur**, une ligne = une action d'un seul utilisateur), cette table
matérialise directement les **arêtes** d'un graphe social : une ligne = un
couple `(user_id_1, user_id_2)` ayant réellement interagi entre eux dans un
contexte donné (un quartier, un événement...), avec le nombre
d'occurrences et les dates de première/dernière occurrence — plutôt qu'une
ligne par message/réaction, ce qui exploserait le volume sans ajouter
d'information utile pour un graphe. Voir `user_interaction_pairs_prompt.md`
pour le détail de la spécification et des choix retenus.

| Colonne                 | Type         | Contenu |
|--------------------------|--------------|---------|
| `id`                       | BIGSERIAL (PK) | Identifiant technique de la ligne |
| `user_id_1`                  | INTEGER      | Le plus petit des deux `user_id` de la paire (`LEAST`) |
| `user_id_2`                    | INTEGER      | Le plus grand des deux `user_id` de la paire (`GREATEST`) — `user_id_1 < user_id_2` toujours, une paire n'est donc jamais dupliquée dans les deux sens |
| `interaction_type`               | VARCHAR(30)  | `echange_messages`, `reaction` ou `participation_evenement`, voir table ci-dessous |
| `context_type`                     | VARCHAR(20)  | `Quartier`, `Evenement`, `Conversation` ou `Bonnes ondes` — le type de contenant dans lequel l'interaction a eu lieu |
| `context_id`                         | BIGINT       | Identifiant du contenant (son sens dépend de `context_type`) |
| `occurrences`                          | INTEGER      | Nombre d'occurrences agrégées sous cette ligne (paires de messages qualifiantes, réactions ou participations) — sert de poids d'arête |
| `first_interaction_at`                   | TIMESTAMP    | Date de la première occurrence agrégée |
| `last_interaction_at`                      | TIMESTAMP    | Date de la dernière occurrence agrégée |

Une contrainte d'unicité porte sur
`(user_id_1, user_id_2, interaction_type, context_type, context_id)` : pour
une même paire d'utilisateurs, un même type d'interaction peut donc donner
lieu à plusieurs lignes si elle a eu lieu dans plusieurs contextes (ex. deux
utilisateurs actifs à la fois dans un même quartier et dans un même
événement), mais jamais deux lignes pour le même contexte.

### Types d'interaction (`interaction_type`)

| `interaction_type`          | `context_type` possibles | Ce que ça représente |
|-------------------------------|-----------------------------|------------------------|
| `echange_messages`               | `Quartier`, `Evenement`, `Conversation`, `Bonnes ondes` | Échange de messages entre les deux utilisateurs (règles de rattachement différentes selon le contenant — commentaires de même publication, commentaire ↔ publication racine, ou simple co-présence pour conversation/bonnes ondes — écart maximum de 30 jours entre les deux messages qualifiants) |
| `reaction`                         | `Quartier`, `Evenement`, `Conversation`, `Bonnes ondes` | Un des deux utilisateurs a réagi à un contenu (publication, commentaire ou message) posté par l'autre |
| `participation_evenement`             | `Evenement`                | Les deux utilisateurs ont une participation acceptée (`join_requests.status = 'accepted'`) au même événement |

Groupes communautaires (`group_type = 'group'`) et entraides
(`group_type = 'action'`) sont volontairement exclus de toutes les règles
ci-dessus (demande explicite, cf. `user_interaction_pairs_prompt.md`) : un
échange de messages ou une réaction dans un groupe ou une entraide n'est
pas comptabilisé ici (il reste néanmoins visible dans
`stats.user_interactions`, ex. `publication_groupe`).

### Construire un graphe à partir des trois tables

- **Nœuds** : une ligne de `stats.user_profile` par utilisateur, avec ses
  attributs pour le clustering (tags, localisation, ancienneté, etc.).
- **Arêtes utilisateur ↔ utilisateur (interactions directes)** : une ligne
  de `stats.user_interaction_pairs` par paire/contexte, `occurrences`
  servant de poids ; cumuler sur `(user_id_1, user_id_2)` pour obtenir un
  poids global tous contextes/types confondus si besoin.
- **Arêtes utilisateur → utilisateur (actions unilatérales)** : filtrer
  `stats.user_interactions` sur `object_type = 'Utilisateur'`
  (`interaction_type IN ('blocage_utilisateur', 'invitation_envoyee')`) —
  `user_id` et `object_id` désignent alors chacun un utilisateur. Non
  repris dans `user_interaction_pairs` (qui ne couvre que les trois
  catégories d'interaction mutuelle listées plus haut).
- **Arêtes utilisateur → objet partagé** (ex: deux utilisateurs actifs
  dans le même groupe communautaire ou la même entraide, hors périmètre de
  `user_interaction_pairs`) : à reconstruire en croisant
  `stats.user_interactions` sur `(object_type, object_id)` identiques pour
  des `user_id` différents (ex: tous les `user_id` ayant
  `publication_groupe` sur le même `object_id` de type `Groupe`).
