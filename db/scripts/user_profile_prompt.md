# Prompt ayant servi à générer user_profile.sql

Ce document décrit la demande et la spécification qui ont permis de générer
`user_profile.sql`. Il permet de régénérer ou d'adapter le script (par
exemple avec un assistant IA) sans avoir à ré-explorer tout le schéma de la
base `entourage-back-preprod`.

## Demande initiale

> À côté de `stats.user_interactions`, je veux créer une table
> `user_profile` qui contient toutes les infos de l'utilisateur nécessaires
> à un profilage, en vue de regrouper les utilisateurs pour faire un
> graphe grâce aux interactions. Ne garder que les données pertinentes.

Contrairement à `user_interactions` (journal d'événements horodatés,
append-only), `user_profile` est un **snapshot** : une seule ligne par
utilisateur, décrivant qui il est au moment de l'exécution du script — pas
ce qu'il a fait. Le croisement des deux tables permet de construire un
graphe (nœuds = utilisateurs avec leurs attributs de `user_profile`, arêtes
= interactions issues de `user_interactions`) puis de regrouper les
utilisateurs par similarité de profil et/ou de comportement.

## Table cible

La table vit dans le schéma `stats`, aux côtés de `user_interactions`.

```sql
CREATE TABLE stats.user_profile (
  user_id                    INTEGER      PRIMARY KEY,
  user_type                  VARCHAR(20),
  goal                       VARCHAR(30),
  targeting_profile          VARCHAR(30),
  validation_status          VARCHAR(20),
  deleted                    BOOLEAN,
  is_staff                   BOOLEAN,
  partner_id                 INTEGER,
  country                    VARCHAR(2),
  postal_code                VARCHAR(8),
  city                       VARCHAR(255),
  lang                       VARCHAR(10),
  age                        INTEGER,
  created_at                 TIMESTAMP,
  last_sign_in_at            TIMESTAMP,
  entourages_count           INTEGER,
  actions_count              INTEGER,
  outings_count               INTEGER,
  neighborhoods_count           INTEGER,
  willing_to_engage_locally      BOOLEAN,
  travel_distance                 INTEGER,
  availability                     JSONB,
  interests                        TEXT,
  involvements                     TEXT,
  concerns                         TEXT,
  orientation                      VARCHAR(60),
  badges                           TEXT
);
```

## Méthode

1. Lire `db/schema.rb`, table `users`, et `app/models/user.rb` en entier
   pour lister tous les attributs disponibles sur un utilisateur.
2. Classer chaque colonne en 3 catégories :
   - **PII / technique, à exclure** : `email`, `phone`, `first_name`,
     `last_name`, `encrypted_password`, `encrypted_admin_password`,
     `reset_admin_password_token`/`_sent_at`, `sms_code`, `token`,
     `device_id`, `device_type`, `avatar_key`, `about` (bio libre),
     `other_interest` (texte libre), `slack_id`, `salesforce_id`
     (identifiants d'outils internes), `searchable_text` (index
     dérivé), `interests_old` (jsonb déprécié, remplacé par les tags),
     `marketing_referer_id`, `old_atd_friend`,
     `old_onboarding_sequence_start_at`, `use_suggestions`,
     `organization_id` (colonne héritée, non lue par le code applicatif —
     seul `partner_id` est utilisé aujourd'hui).
   - **Pertinent pour le profilage/segmentation**, à garder :
     `user_type` (pro/public), `goal`, `targeting_profile`
     (précisent l'intention : aide/entraide, staff, partenaire...),
     `validation_status`, `deleted` (pour pouvoir filtrer les comptes
     invalides), `partner_id` (rattachement à une organisation), `lang`,
     `willing_to_engage_locally`, `travel_distance`, `availability`
     (jsonb de disponibilité), les compteurs dénormalisés
     `entourages_count`/`actions_count`/`outings_count`/
     `neighborhoods_count` (niveau d'engagement), `created_at`
     (ancienneté), `last_sign_in_at` (récence).
   - **Dérivé pour limiter le PII tout en gardant le signal utile** :
     - `birthdate` (string libre) → recalculé en `age` (entier), jamais
       stocké tel quel.
     - `roles` (jsonb) + `admin`/`manager`/`super_admin` (booléens) →
       condensés en un seul flag `is_staff`, pour pouvoir exclure les
       comptes internes du clustering sans exposer le détail des rôles.
     - `address` (via `address_id`) → seuls `country`, `postal_code` et
       `city` sont conservés, sur demande explicite ; pas de coordonnées
       GPS (`latitude`/`longitude`) ni de `street_address`/
       `google_place_id`, jugées trop précises et non nécessaires à un
       regroupement par similarité.
3. Les tags (`interests`, `involvements`, `concerns`, `orientations`) sont
   stockés via `acts_as_taggable_on` dans la table polymorphe `taggings`
   (`taggable_type = 'User'`, `context` = nom du contexte) jointe à `tags`.
   Ce sont des axes de profilage centraux (ce sont eux qui alimentent déjà
   les recommandations dans l'app) : chacun est agrégé en une liste
   `TEXT` séparée par des virgules (`string_agg`), sauf `orientation` qui
   ne porte qu'une seule valeur par utilisateur (cf. `orientation=` dans
   `app/models/concerns/orientable.rb`) et est donc pris tel quel (1
   sous-requête `LIMIT 1`).
3bis. `user_badges` (`badge_tag`, un par type de badge, `active` filtre les
   badges retirés) est un signal de reconnaissance/engagement au même
   titre que les tags : agrégé en `badges` (`TEXT`, `string_agg` des
   `badge_tag` actifs), sur le même modèle que `interests`/
   `involvements`/`concerns`. C'est la même source que la section
   `badge_obtenu` de `user_interactions.sql`, mais ici sous forme d'état
   courant (liste des badges actifs) plutôt que d'un événement par badge
   obtenu.
4. La table est un **snapshot complet**, pas une suite de sections
   append-only comme `user_interactions` : un utilisateur n'a qu'un seul
   profil courant, contrairement à ses interactions qui s'accumulent dans
   le temps. Le script fait donc un `TRUNCATE` puis un `INSERT` unique sur
   toute la table `users`, rejouable sans risque de doublons.

## Colonnes explorées mais volontairement exclues

- `email`, `phone`, `first_name`, `last_name`, `device_id`, `device_type`,
  `avatar_key`, `about`, `other_interest` : identifiants directs ou texte
  libre pouvant contenir du PII, sans valeur ajoutée pour un clustering
  par similarité de profil.
- `encrypted_password`, `encrypted_admin_password`,
  `reset_admin_password_token`, `reset_admin_password_sent_at`,
  `sms_code`, `token`, `slack_id`, `salesforce_id` : secrets ou
  identifiants techniques/internes.
- `searchable_text`, `interests_old` : colonnes dérivées ou dépréciées,
  redondantes avec les tags actuels.
- `organization_id` : colonne présente en base mais non référencée dans
  `app/models` (remplacée par `partner_id`).
- `community` : écartée sur demande.
- `marketing_referer_id`, `old_atd_friend`,
  `old_onboarding_sequence_start_at`, `use_suggestions`,
  `first_sign_in_at` (redondant avec `created_at`/`last_sign_in_at`),
  `options` (jsonb de feature flags internes) : signal jugé non pertinent
  pour un profilage utilisateur.
- Latitude/longitude et adresse précise (`addresses.street_address`,
  `latitude`, `longitude`, `google_place_id`) : seuls `country`,
  `postal_code` et `city` sont conservés (adresse demandée explicitement,
  mais limitée à ces deux derniers champs).
- `birthdate` brut : remplacé par `age` calculé.
- `roles`, `admin`, `manager`, `super_admin` bruts : condensés en
  `is_staff`.

## Points d'attention pour la ré-exécution

- Le script reconstruit la table en entier (`TRUNCATE` + `INSERT`) : à
  la différence de `user_interactions.sql`, il n'est pas idempotent par
  section — le rejouer écrase tout le snapshot précédent. C'est voulu :
  la table doit refléter l'état courant des utilisateurs, pas un
  historique.
- `age` est `NULL` si `birthdate` ne respecte pas le format `YYYY-MM-DD`
  attendu (le champ est une string libre en base, pas un type `date`).
- Les colonnes `interests`/`involvements`/`concerns` peuvent être vides
  (`NULL`) pour un utilisateur qui n'a renseigné aucun tag dans le
  contexte correspondant.
- `is_staff` agrège plusieurs signaux (`admin`, `manager`, `super_admin`,
  rôle `moderator` dans `roles`) : à affiner si un cas d'usage a besoin
  de distinguer plus finement modérateur / admin / super-admin.
- Sur `users`, le volume est plus faible que sur `chat_messages`/
  `join_requests`, donc pas d'enjeu de performance particulier attendu ;
  à vérifier tout de même en préprod avant de jouer en prod.
