-- =====================================================================
-- Script : construction de la table user_profile
-- But    : consolider en une seule table les attributs d'un utilisateur
--          pertinents pour un profilage / clustering (regroupement des
--          utilisateurs en vue d'un graphe construit à partir de
--          stats.user_interactions).
--
-- Usage  : à exécuter à la main, d'abord sur preprod puis sur prod.
--          Contrairement à user_interactions.sql (événements horodatés,
--          append-only), cette table est un snapshot : chaque exécution
--          la reconstruit intégralement (TRUNCATE puis INSERT).
--
-- Voir aussi : user_profile_prompt.md (même dossier) qui documente la
-- spécification ayant servi à générer ce script.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Création du schéma et de la table cible
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS stats;

CREATE TABLE IF NOT EXISTS stats.user_profile (
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
  actions_count               INTEGER,
  outings_count                INTEGER,
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

CREATE INDEX IF NOT EXISTS index_user_profile_on_goal ON stats.user_profile (goal);
CREATE INDEX IF NOT EXISTS index_user_profile_on_postal_code ON stats.user_profile (postal_code);
CREATE INDEX IF NOT EXISTS index_user_profile_on_partner_id ON stats.user_profile (partner_id);


-- ---------------------------------------------------------------------
-- 1. Reconstruction complète du snapshot (TRUNCATE + INSERT)
-- ---------------------------------------------------------------------
TRUNCATE TABLE stats.user_profile;

INSERT INTO stats.user_profile (
  user_id, user_type, goal, targeting_profile, validation_status,
  deleted, is_staff, partner_id, country, postal_code, city, lang, age,
  created_at, last_sign_in_at, entourages_count, actions_count, outings_count,
  neighborhoods_count, willing_to_engage_locally, travel_distance,
  availability, interests, involvements, concerns, orientation, badges
)
SELECT
  u.id,
  u.user_type,
  u.goal,
  u.targeting_profile,
  u.validation_status,
  u.deleted,
  (u.admin OR u.manager OR COALESCE(u.super_admin, false) OR (u.roles @> '["moderator"]'::jsonb)),
  u.partner_id,
  a.country,
  a.postal_code,
  a.city,
  u.lang,
  CASE WHEN u.birthdate ~ '^\d{4}-\d{2}-\d{2}$'
    THEN DATE_PART('year', AGE(CURRENT_DATE, u.birthdate::date))::int
  END,
  u.created_at,
  u.last_sign_in_at,
  u.entourages_count,
  u.actions_count,
  u.outings_count,
  u.neighborhoods_count,
  u.willing_to_engage_locally,
  u.travel_distance,
  u.availability,
  (SELECT string_agg(t.name, ',' ORDER BY t.name)
     FROM taggings tg JOIN tags t ON t.id = tg.tag_id
     WHERE tg.taggable_type = 'User' AND tg.taggable_id = u.id AND tg.context = 'interests'),
  (SELECT string_agg(t.name, ',' ORDER BY t.name)
     FROM taggings tg JOIN tags t ON t.id = tg.tag_id
     WHERE tg.taggable_type = 'User' AND tg.taggable_id = u.id AND tg.context = 'involvements'),
  (SELECT string_agg(t.name, ',' ORDER BY t.name)
     FROM taggings tg JOIN tags t ON t.id = tg.tag_id
     WHERE tg.taggable_type = 'User' AND tg.taggable_id = u.id AND tg.context = 'concerns'),
  (SELECT t.name
     FROM taggings tg JOIN tags t ON t.id = tg.tag_id
     WHERE tg.taggable_type = 'User' AND tg.taggable_id = u.id AND tg.context = 'orientations'
     ORDER BY tg.id LIMIT 1),
  (SELECT string_agg(ub.badge_tag, ',' ORDER BY ub.badge_tag)
     FROM user_badges ub
     WHERE ub.user_id = u.id AND ub.active)
FROM users u
LEFT JOIN addresses a ON a.id = u.address_id
WHERE u.community = 'entourage'
  AND u.last_sign_in_at IS NOT NULL;


-- ---------------------------------------------------------------------
-- Fin : mise à jour des statistiques pour l'optimiseur de requêtes
-- ---------------------------------------------------------------------
ANALYZE stats.user_profile;
COMMIT;

-- Contrôle rapide : répartition par objectif
-- SELECT goal, count(*)
-- FROM stats.user_profile
-- GROUP BY 1
-- ORDER BY 1;
