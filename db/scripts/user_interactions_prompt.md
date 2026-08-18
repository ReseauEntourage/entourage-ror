# Prompt ayant servi à générer user_interactions.sql

Ce document décrit la demande et la spécification qui ont permis de générer
`user_interactions.sql`. Il permet de régénérer ou d'adapter le script
(par exemple avec un assistant IA) sans avoir à ré-explorer tout le schéma
de la base `entourage-back-preprod`.

## Demande initiale

> Je voudrais avoir toutes les interactions d'un utilisateur avec les autres
> depuis les données stockées dans la base, mais aussi les sessions, les
> activités dans les groupes et les événements.
>
> J'aimerais les requêtes SQL pour remplir une seule table qui contiendrait :
> - user-id
> - type d'interaction
> - objet de l'interaction (session, app user, group, event, ...)
> - id de cet objet
> - date de l'interaction
> - description additionnelle optionnelle de cette interaction
>
> Il faut donc parcourir toutes les tables de la DB pour voir quelles infos
> sont susceptibles d'être exportées dans cette table.
>
> Le but est de générer un script SQL que je jouerai à la main dans la base
> de preprod puis de prod.

## Table cible

La table vit dans le schéma `stats` (et non `public`), aux côtés des autres
tables d'analytics/reporting.

```sql
CREATE SCHEMA IF NOT EXISTS stats;

CREATE TABLE stats.user_interactions (
  id               BIGSERIAL PRIMARY KEY,
  user_id          INTEGER      NOT NULL,
  interaction_type VARCHAR(40)  NOT NULL,
  object_type      VARCHAR(40)  NOT NULL,
  object_id        BIGINT,
  interaction_at   TIMESTAMP    NOT NULL,
  description      TEXT
);
```

## Méthode

1. Lire `db/schema.rb` en entier pour lister toutes les tables de la base
   (application Rails `entourage-back-preprod`).
2. Pour chaque table candidate, vérifier dans `app/models/*.rb` :
   - si elle porte un `user_id` (ou équivalent) directement exploitable,
   - si elle possède une colonne date exploitable (`created_at`, ou une
     date métier plus précise comme `accepted_at`, `participate_at`,
     `matched_at`, `awarded_at`, `connected_at`...),
   - si elle référence un objet polymorphique (`*_type` / `*_id`) qu'il
     faut retraduire en catégorie métier lisible (Groupe / Événement /
     Conversation / Quartier / Bonnes ondes / Utilisateur / Partenaire...).
3. Le modèle `Entourage` (table `entourages`) sert à la fois pour les
   « groupes » communautaires (`group_type` = `group`), les « entraides »
   (`group_type` = `action`, classes `Action`/`Contribution`/`Solicitation`),
   les « événements » (`group_type` = `outing`, classe `Outing`) et les
   conversations privées (`group_type` = `conversation`). Chaque fois
   qu'une table référence un `Entourage` de façon polymorphique
   (`join_requests.joinable_type`, `chat_messages.messageable_type`,
   `user_reactions.instance_type`), il faut rejoindre `entourages` pour
   retrouver le `group_type` réel et choisir le bon `object_type` (Groupe /
   Entraide / Événement / Conversation). Sur demande explicite, `group` et
   `action` sont distingués à la fois en `object_type` (Groupe / Entraide)
   et en `interaction_type` (ex. `demande_adhesion` vs
   `demande_adhesion_entraide`) pour la création, l'adhésion et la
   confirmation d'adhésion ; pour les messages en revanche, un seul
   `interaction_type` `publication_groupe` couvre `group` et `action`
   (object_type reste `Groupe` dans les deux cas), pour le distinguer d'un
   `message_envoye` de conversation/événement/quartier/bonnes ondes.
4. Exclure les tables qui ne représentent pas une interaction utilisateur
   exploitable telle quelle : tables de configuration (`options`,
   `moderation_areas`, `reactions`...), tables sans `user_id` direct
   (`user_relationships` n'a pas de colonne date exploitable dans ce
   schéma), tables purement techniques (`rpush_*`, `image_resize_actions`,
   `sensitive_words*`...), tables déjà agrégées (`weekly_activities`,
   `denorm_daily_engagements*`), ou trop indirectement liées à un
   utilisateur inscrit (`donations.app_user_id`, `sms_deliveries` qui n'a
   qu'un `phone_number`).
5. Pour chaque table retenue, écrire un bloc `DELETE ... WHERE
   interaction_type = 'xxx'` suivi d'un `INSERT INTO user_interactions
   SELECT ...`, afin que le script soit rejouable sans créer de doublons
   (idempotence par section).
6. Regrouper les blocs par thème dans cet ordre : sessions, groupes/
   événements/quartiers (création, adhésion, participation, messages,
   réactions), interactions directes entre utilisateurs (blocage,
   invitation), partenaires, bonnes ondes, sondages, badges, notifications,
   contenu pédagogique.

## Sources de données retenues (table → interaction_type)

| Table                    | interaction_type                          | Commentaire |
|---------------------------|--------------------------------------------|-------------|
| `login_histories`          | `connexion`                                | 1 ligne/heure/utilisateur |
| `session_histories`        | `session`                                  | 1 ligne/jour/plateforme |
| `entourages`                | `creation_groupe` / `creation_entraide` / `creation_evenement` / `creation_conversation` | selon `group_type` (`group` / `action` / `outing` / `conversation`) |
| `neighborhoods`             | `creation_quartier`                        | |
| `join_requests`             | `demande_adhesion` / `demande_adhesion_entraide` | date = `requested_at` ou `created_at` ; type `_entraide` si `group_type = 'action'` |
| `join_requests`             | `adhesion_confirmee` / `adhesion_confirmee_entraide` | date = `accepted_at`, si non nul ; type `_entraide` si `group_type = 'action'` |
| `join_requests`             | `participation_evenement`                   | date = `participate_at`, si non nul, uniquement events |
| `chat_messages`             | `message_envoye` / `publication_groupe`     | messages actifs/mis à jour, hors messages techniques ; `publication_groupe` si `group_type IN ('group', 'action')`, sinon `message_envoye` (conversations, événements, quartiers, bonnes ondes) |
| `user_reactions`            | `reaction`                                  | toujours sur un `ChatMessage` |
| `user_blocked_users`        | `blocage_utilisateur`                       | interaction directe entre 2 utilisateurs |
| `entourage_invitations`     | `invitation_envoyee`                        | interaction directe entre 2 utilisateurs |
| `followings`                | `suivi_partenaire`                          | |
| `partner_join_requests`     | `demande_partenariat`                       | |
| `user_smalltalks`           | `inscription_bonnes_ondes`                  | |
| `user_smalltalks`           | `match_bonnes_ondes`                        | date = `matched_at`, si non nul |
| `survey_responses`          | `reponse_sondage`                           | |
| `user_badges`                | `badge_obtenu`                              | badges actifs uniquement |
| `inapp_notifications`       | `notification_recue`                        | inclut le `sender_id` si connu |
| `users_resources` (+ `resources`) | `visionnage_contenu_pedago`           | uniquement `watched = true`, date = `updated_at` |

## Tables explorées mais volontairement exclues

- `user_relationships` : pas de colonne date dans le schéma actuel.
- `donations` : liée à `app_user_id`, pas nécessairement un utilisateur
  inscrit de la table `users`.
- `sms_deliveries` : pas de `user_id`, seulement un `phone_number`.
- `email_deliveries` : écartée sur demande (communication descendante de
  l'app vers l'utilisateur, pas une interaction avec un autre utilisateur,
  un groupe ou un événement).
- `weekly_activities`, `denorm_daily_engagements*` : déjà des agrégats
  dérivés d'autres tables, pas des événements bruts.
- `moderator_reads`, `user_next_steps` : activité côté modérateur/backoffice
  ou suggestions système, pas une interaction utilisateur au sens demandé.
  À ajouter facilement sur le même modèle si besoin.
- Tables techniques (`rpush_*`, `image_resize_actions`,
  `sensitive_words*`, `openai_*`, `matchings`, `translations`...).

## Points d'attention pour la ré-exécution

- Le script est découpé en sections indépendantes et idempotentes
  (`DELETE` puis `INSERT` par `interaction_type`) : il peut être rejoué
  section par section, y compris après un échec partiel.
- Sur `chat_messages` et `join_requests`, les volumes peuvent être
  importants en production : envisager de lancer ces sections hors heures
  de forte charge, et de vérifier le temps d'exécution en préprod avant
  de jouer en prod.
- La table est **partitionnée par RANGE (année) sur `interaction_at`**
  (une partition `stats.user_interactions_<année>` par année de 2015 à
  2035, plus une partition `_default` pour toute date hors bornes) —
  transparent pour les sections 1 à 19, qui continuent de cibler
  `stats.user_interactions` (le parent) sans rien changer. Même logique
  que `db/migrate/20260505120000_partition_join_requests_by_type_and_year.rb`,
  mais sans le niveau de partitionnement LIST par type (pas de notion de
  "type" polymorphique équivalente à `joinable_type` ici : un seul niveau
  RANGE suffit). Si la table existait déjà en version non partitionnée,
  la section 0 la renomme automatiquement en
  `stats.user_interactions_unpartitioned` (à supprimer manuellement une
  fois la nouvelle table repeuplée par les sections suivantes et
  vérifiée) plutôt que de tenter une conversion en place.
- Pour étendre la plage de partitions au-delà de 2035, ajouter une
  nouvelle section rejouant uniquement la boucle `DO $$ ... FOR yr IN
  ... $$` de la section 0 avec la plage voulue (les partitions déjà
  créées ne sont pas affectées grâce à `IF NOT EXISTS`).
- `db/schema.rb` contenait une anomalie (blocs `translations`/`users` et
  plusieurs autres tables `user_*` dupliqués, avec un premier bloc `users`
  tronqué, et deux tables `user_next_steps`/`user_suggestions` provenant
  d'une branche non fusionnée `journee-equipe-2`, introduites par erreur
  dans le commit `ea128a10d7`). Cela n'affectait pas ce script, mais a été
  corrigé séparément dans le dépôt (suppression des 248 lignes dupliquées,
  restauration des index manquants sur `users`).

## Historique des ajustements

- 2026-08-18 : la table cible est déplacée du schéma `public` vers le
  schéma `stats` (`stats.user_interactions`), toutes les instructions du
  script (`CREATE TABLE`, index, `DELETE`, `INSERT`, `ANALYZE`) sont
  qualifiées en conséquence.
- 2026-08-18 : à la relecture, ajout du contenu pédagogique
  (`resources`/`users_resources`, `interaction_type = visionnage_contenu_pedago`,
  uniquement `watched = true`), et séparation sur demande de deux paires
  jusque-là fusionnées : `creation_groupe`/`creation_entraide` et
  `demande_adhesion`/`demande_adhesion_entraide` (+ équivalent
  `adhesion_confirmee`) selon `group_type` ('group' vs 'action'), ainsi que
  `message_envoye`/`publication_groupe` selon que le message est posté
  dans un groupe ou une entraide (`group`/`action`) ou ailleurs
  (conversation/événement/quartier/bonnes ondes).
