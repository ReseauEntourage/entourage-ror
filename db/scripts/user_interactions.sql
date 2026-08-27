-- =====================================================================
-- Script : construction de la table user_interactions
-- But    : consolider en une seule table toutes les interactions
--          détectables d'un utilisateur (sessions, groupes, événements,
--          quartiers, autres utilisateurs, partenaires, etc.)
--
-- Usage  : à exécuter à la main, section par section, d'abord sur
--          preprod puis sur prod. Chaque section est idempotente
--          (DELETE puis INSERT sur son propre interaction_type), donc
--          le script peut être rejoué sans créer de doublons.
--
-- Partitionnement : la table est partitionnée par RANGE (année) sur
-- interaction_at, une partition par année (voir section 0). C'est
-- transparent pour les sections 1 à 19 : DELETE/INSERT/ANALYZE
-- continuent de cibler stats.user_interactions normalement, Postgres
-- routant chaque ligne vers la bonne partition. Même approche que
-- db/migrate/20260505120000_partition_join_requests_by_type_and_year.rb
-- (partitionnement par année), sans le niveau LIST par type ici.
--
-- Voir aussi : user_interactions_prompt.md (même dossier) qui documente
-- la spécification ayant servi à générer ce script.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Création du schéma et de la table cible, partitionnée par année
--    sur interaction_at.
--
--    Si une version non partitionnée de la table existe déjà (le script
--    a été joué avant la mise en place du partitionnement), elle est
--    mise de côté : ses données sont de toute façon régénérées à
--    l'identique par les sections 1 à 19, qui repartent des tables
--    sources — inutile donc de les recopier.
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS stats;

-- Clé de partition (interaction_at) obligatoirement incluse dans la clé
-- primaire ; l'unicité de id reste garantie globalement par la séquence
-- partagée, pas par la contrainte de clé primaire (même remarque que
-- pour join_requests).
CREATE TABLE IF NOT EXISTS stats.user_interactions (
  id               BIGSERIAL,
  user_id          INTEGER      NOT NULL,
  interaction_type VARCHAR(40)  NOT NULL,
  object_type      VARCHAR(40)  NOT NULL,
  object_id        BIGINT,
  interaction_at   TIMESTAMP    NOT NULL,
  description      TEXT,
  CONSTRAINT user_interactions_pkey PRIMARY KEY (id, interaction_at)
) PARTITION BY RANGE (interaction_at);

-- Une partition par année (2015 à 2035, même plage que
-- db/migrate/20260505120000_partition_join_requests_by_type_and_year.rb),
-- plus une partition "default" qui absorbe toute date hors bornes
-- (evite un échec d'INSERT si une donnée source a une date aberrante).
DO $$
DECLARE
  yr INT;
BEGIN
  FOR yr IN 2015..2035 LOOP
    EXECUTE format(
      'CREATE TABLE IF NOT EXISTS stats.user_interactions_%1$s PARTITION OF stats.user_interactions FOR VALUES FROM (%2$L) TO (%3$L)',
      yr, yr || '-01-01', (yr + 1) || '-01-01'
    );
  END LOOP;
END $$;

CREATE TABLE IF NOT EXISTS stats.user_interactions_default PARTITION OF stats.user_interactions DEFAULT;

CREATE INDEX IF NOT EXISTS index_user_interactions_on_user_id ON stats.user_interactions (user_id);
CREATE INDEX IF NOT EXISTS index_user_interactions_on_interaction_type ON stats.user_interactions (interaction_type);
CREATE INDEX IF NOT EXISTS index_user_interactions_on_interaction_at ON stats.user_interactions (interaction_at);
CREATE INDEX IF NOT EXISTS index_user_interactions_on_object ON stats.user_interactions (object_type, object_id);


-- ---------------------------------------------------------------------
-- 1. Connexions (login_histories)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'connexion';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  lh.user_id,
  'connexion',
  'Session',
  NULL,
  lh.connected_at,
  NULL
FROM login_histories lh;


-- ---------------------------------------------------------------------
-- 2. Sessions applicatives (session_histories : 1 ligne / jour / plateforme)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'session';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  sh.user_id,
  'session',
  'Session',
  NULL,
  sh.date::timestamp,
  'plateforme=' || sh.platform ||
    COALESCE(', notifications=' || sh.notifications_permissions, '')
FROM session_histories sh;


-- ---------------------------------------------------------------------
-- 3. Création d'un groupe / entraide / événement / conversation (entourages)
--    group_type = 'group'        -> Groupe
--    group_type = 'action'       -> Entraide
--    group_type = 'outing'       -> Evenement
--    group_type = 'conversation' -> Conversation (message privé 1-to-1)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions
WHERE interaction_type IN ('creation_groupe', 'creation_entraide', 'creation_evenement', 'creation_conversation');

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  e.user_id,
  CASE e.group_type
    WHEN 'outing'       THEN 'creation_evenement'
    WHEN 'conversation' THEN 'creation_conversation'
    WHEN 'action'        THEN 'creation_entraide'
    ELSE                     'creation_groupe'
  END,
  CASE e.group_type
    WHEN 'outing'       THEN 'Evenement'
    WHEN 'conversation' THEN 'Conversation'
    WHEN 'action'        THEN 'Entraide'
    ELSE                     'Groupe'
  END,
  e.id,
  e.created_at,
  e.title
FROM entourages e;


-- ---------------------------------------------------------------------
-- 4. Création d'un quartier (neighborhoods)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'creation_quartier';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  n.user_id,
  'creation_quartier',
  'Quartier',
  n.id,
  n.created_at,
  n.name
FROM neighborhoods n;


-- ---------------------------------------------------------------------
-- 5. Demandes d'adhésion à un groupe / entraide / événement / quartier /
--    bonnes ondes (join_requests, une ligne par demande - date de la
--    demande). Les entraides (group_type = 'action') sont distinguées
--    des groupes communautaires (group_type = 'group') via un
--    interaction_type dédié.
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type IN ('demande_adhesion', 'demande_adhesion_entraide');

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  jr.user_id,
  CASE
    WHEN jr.joinable_type = 'Entourage' AND e.group_type = 'action' THEN 'demande_adhesion_entraide'
    ELSE 'demande_adhesion'
  END,
  CASE
    WHEN jr.joinable_type = 'Entourage' THEN
      CASE e.group_type
        WHEN 'outing'       THEN 'Evenement'
        WHEN 'conversation' THEN 'Conversation'
        WHEN 'action'       THEN 'Entraide'
        ELSE                     'Groupe'
      END
    WHEN jr.joinable_type = 'Neighborhood' THEN 'Quartier'
    WHEN jr.joinable_type = 'Smalltalk'    THEN 'Bonnes ondes'
    ELSE jr.joinable_type
  END,
  jr.joinable_id,
  COALESCE(jr.requested_at, jr.created_at),
  'statut=' || jr.status || ', role=' || jr.role
FROM join_requests jr
LEFT JOIN entourages e ON jr.joinable_type = 'Entourage' AND e.id = jr.joinable_id
WHERE jr.accepted_at IS NULL;


-- ---------------------------------------------------------------------
-- 6. Adhésions confirmées (join_requests.accepted_at renseigné). Même
--    distinction groupe / entraide que la section précédente.
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type IN ('adhesion_confirmee', 'adhesion_confirmee_entraide');

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  jr.user_id,
  CASE
    WHEN jr.joinable_type = 'Entourage' AND e.group_type = 'action' THEN 'adhesion_confirmee_entraide'
    ELSE 'adhesion_confirmee'
  END,
  CASE
    WHEN jr.joinable_type = 'Entourage' THEN
      CASE e.group_type
        WHEN 'outing'       THEN 'Evenement'
        WHEN 'conversation' THEN 'Conversation'
        WHEN 'action'       THEN 'Entraide'
        ELSE                     'Groupe'
      END
    WHEN jr.joinable_type = 'Neighborhood' THEN 'Quartier'
    WHEN jr.joinable_type = 'Smalltalk'    THEN 'Bonnes ondes'
    ELSE jr.joinable_type
  END,
  jr.joinable_id,
  jr.accepted_at,
  'role=' || jr.role
FROM join_requests jr
LEFT JOIN entourages e ON jr.joinable_type = 'Entourage' AND e.id = jr.joinable_id
WHERE jr.accepted_at IS NOT NULL;


-- ---------------------------------------------------------------------
-- 7. Participation confirmée à un événement (join_requests.participate_at)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'participation_evenement';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  jr.user_id,
  'participation_evenement',
  'Evenement',
  jr.joinable_id,
  jr.participate_at,
  NULL
FROM join_requests jr
WHERE jr.participate_at IS NOT NULL
  AND jr.joinable_type = 'Entourage';


-- ---------------------------------------------------------------------
-- 8. Messages envoyés (chat_messages : groupes, entraides, événements,
--    conversations, quartiers, bonnes ondes). On exclut les messages
--    supprimés et les messages techniques générés par le système.
--    Les messages postés dans un groupe communautaire ou une entraide
--    (group_type IN ('group', 'action')) sont comptés comme
--    'publication_groupe' plutôt que 'message_envoye', pour distinguer
--    une publication dans un groupe d'un message de conversation/événement.
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type IN ('message_envoye', 'publication_groupe');

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  cm.user_id,
  CASE
    WHEN cm.messageable_type = 'Entourage' AND e.group_type IN ('group', 'action') THEN 'publication_groupe'
    ELSE 'message_envoye'
  END,
  CASE
    WHEN cm.messageable_type = 'Entourage' THEN
      CASE e.group_type
        WHEN 'outing'       THEN 'Evenement'
        WHEN 'conversation' THEN 'Conversation'
        ELSE                     'Groupe'
      END
    WHEN cm.messageable_type = 'Neighborhood' THEN 'Quartier'
    WHEN cm.messageable_type = 'Smalltalk'    THEN 'Bonnes ondes'
    ELSE cm.messageable_type
  END,
  cm.messageable_id,
  cm.created_at,
  LEFT(cm.content, 255)
FROM chat_messages cm
LEFT JOIN entourages e ON cm.messageable_type = 'Entourage' AND e.id = cm.messageable_id
WHERE cm.status <> 'deleted'
  AND cm.message_type NOT IN ('status_update', 'auto', 'broadcast');


-- ---------------------------------------------------------------------
-- 9. Réactions à un message (user_reactions, toujours sur des ChatMessage)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'reaction';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  ur.user_id,
  'reaction',
  'Message',
  ur.instance_id,
  ur.created_at,
  r.key
FROM user_reactions ur
LEFT JOIN reactions r ON r.id = ur.reaction_id
WHERE ur.instance_type = 'ChatMessage';


-- ---------------------------------------------------------------------
-- 10. Blocage d'un autre utilisateur (user_blocked_users)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'blocage_utilisateur';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  ubu.user_id,
  'blocage_utilisateur',
  'Utilisateur',
  ubu.blocked_user_id,
  ubu.created_at,
  'bloqué'
FROM user_blocked_users ubu;


-- ---------------------------------------------------------------------
-- 11. Invitation d'un autre utilisateur dans un groupe (entourage_invitations)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'invitation_envoyee';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  ei.inviter_id,
  'invitation_envoyee',
  'Utilisateur',
  ei.invitee_id,
  ei.created_at,
  'entourage_id=' || ei.invitable_id || ', statut=' || ei.status
FROM entourage_invitations ei;


-- ---------------------------------------------------------------------
-- 12. Suivi d'un partenaire (followings)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'suivi_partenaire';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  f.user_id,
  'suivi_partenaire',
  'Partenaire',
  f.partner_id,
  f.created_at,
  CASE WHEN f.active THEN 'actif' ELSE 'inactif' END
FROM followings f
WHERE f.created_at IS NOT NULL;


-- ---------------------------------------------------------------------
-- 13. Demande de partenariat (partner_join_requests)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'demande_partenariat';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  pjr.user_id,
  'demande_partenariat',
  'Partenaire',
  pjr.partner_id,
  pjr.created_at,
  pjr.new_partner_name
FROM partner_join_requests pjr
WHERE pjr.created_at IS NOT NULL;


-- ---------------------------------------------------------------------
-- 14. Inscription aux bonnes ondes (mise en relation avec d'autres utilisateurs)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'inscription_bonnes_ondes';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  us.user_id,
  'inscription_bonnes_ondes',
  'Bonnes ondes',
  us.smalltalk_id,
  us.created_at,
  NULL
FROM user_smalltalks us;


-- ---------------------------------------------------------------------
-- 15. Match bonnes ondes obtenu (user_smalltalks.matched_at)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'match_bonnes_ondes';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  us.user_id,
  'match_bonnes_ondes',
  'Bonnes ondes',
  us.smalltalk_id,
  us.matched_at,
  NULL
FROM user_smalltalks us
WHERE us.matched_at IS NOT NULL;


-- ---------------------------------------------------------------------
-- 16. Réponse à un sondage (survey_responses)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'reponse_sondage';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  sr.user_id,
  'reponse_sondage',
  'Message',
  sr.chat_message_id,
  sr.created_at,
  NULL
FROM survey_responses sr;


-- ---------------------------------------------------------------------
-- 17. Badge obtenu (user_badges)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'badge_obtenu';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  ub.user_id,
  'badge_obtenu',
  'Badge',
  NULL,
  COALESCE(ub.awarded_at, ub.created_at),
  ub.badge_tag
FROM user_badges ub
WHERE ub.active;


-- ---------------------------------------------------------------------
-- 18. Notification in-app reçue, avec l'expéditeur si connu
--     (inapp_notifications.sender_id -> interaction envoyée par un autre user)
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'notification_recue';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  inn.user_id,
  'notification_recue',
  COALESCE(inn.instance_baseclass, inn.instance, 'Notification'),
  inn.instance_id,
  inn.created_at,
  'sender_id=' || COALESCE(inn.sender_id::text, 'system') ||
    COALESCE(', titre=' || inn.title, '')
FROM inapp_notifications inn;


-- ---------------------------------------------------------------------
-- 19. Contenu pédagogique visionné (resources / users_resources).
--     Uniquement les ressources marquées comme visionnées (watched = true),
--     date = updated_at (date du visionnage).
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interactions WHERE interaction_type = 'visionnage_contenu_pedago';

INSERT INTO stats.user_interactions (user_id, interaction_type, object_type, object_id, interaction_at, description)
SELECT
  ur.user_id,
  'visionnage_contenu_pedago',
  'Contenu pédago',
  ur.resource_id,
  ur.updated_at,
  r.name || ' (categorie=' || r.category || COALESCE(', tag=' || r.tag, '') || ')'
FROM users_resources ur
JOIN resources r ON r.id = ur.resource_id
WHERE ur.watched = true;


-- ---------------------------------------------------------------------
-- Fin : mise à jour des statistiques pour l'optimiseur de requêtes
-- ---------------------------------------------------------------------
ANALYZE stats.user_interactions;

-- Contrôle rapide : répartition par type d'interaction
-- SELECT interaction_type, object_type, count(*), min(interaction_at), max(interaction_at)
-- FROM stats.user_interactions
-- GROUP BY 1, 2
-- ORDER BY 1, 2;
