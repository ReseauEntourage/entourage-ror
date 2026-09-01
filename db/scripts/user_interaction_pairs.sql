-- =====================================================================
-- Script : construction de la table user_interaction_pairs
-- But    : matérialiser les interactions ENTRE DEUX UTILISATEURS
--          (arêtes d'un graphe social), au sens strict défini par la
--          spécification métier (cf. user_interaction_pairs_prompt.md) :
--            1. échange de messages (avec règles spécifiques par type de
--               contenant : quartier, événement, conversation, bonnes ondes)
--            2. réaction sur un contenu posté par un autre utilisateur
--            3. participation acceptée à un même événement
--
--          Contrairement à stats.user_interactions (journal d'activité
--          par utilisateur, une ligne = une action d'un seul utilisateur),
--          cette table est un journal PAR PAIRE : une ligne = un couple
--          (user_id_1, user_id_2) en interaction dans un contexte donné,
--          avec le nombre d'occurrences et les dates de première/dernière
--          occurrence (plutôt qu'une ligne par message/réaction, ce qui
--          exploserait le volume sans ajouter d'information utile pour un
--          graphe).
--
-- Usage  : à exécuter à la main, section par section, d'abord sur
--          preprod puis sur prod. Chaque section est idempotente
--          (DELETE puis INSERT sur son propre interaction_type), donc
--          le script peut être rejoué sans créer de doublons.
--
-- Voir aussi : user_interaction_pairs_prompt.md (même dossier) qui
-- documente la spécification ayant servi à générer ce script, y compris
-- les hypothèses retenues sur les points laissés ouverts par la demande.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Création du schéma et de la table cible.
--    user_id_1 < user_id_2 par construction (CHECK), afin qu'une paire
--    ne soit jamais dupliquée dans les deux sens.
-- ---------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS stats;

CREATE TABLE IF NOT EXISTS stats.user_interaction_pairs (
  id                    BIGSERIAL PRIMARY KEY,
  user_id_1             INTEGER      NOT NULL,
  user_id_2             INTEGER      NOT NULL,
  interaction_type      VARCHAR(30)  NOT NULL,
  context_type          VARCHAR(20)  NOT NULL,
  context_id            BIGINT       NOT NULL,
  occurrences           INTEGER      NOT NULL,
  first_interaction_at  TIMESTAMP    NOT NULL,
  last_interaction_at   TIMESTAMP    NOT NULL,
  CONSTRAINT user_interaction_pairs_ordered_pair CHECK (user_id_1 < user_id_2),
  CONSTRAINT user_interaction_pairs_uniq UNIQUE (user_id_1, user_id_2, interaction_type, context_type, context_id)
);

CREATE INDEX IF NOT EXISTS index_uip_on_user_id_1 ON stats.user_interaction_pairs (user_id_1);
CREATE INDEX IF NOT EXISTS index_uip_on_user_id_2 ON stats.user_interaction_pairs (user_id_2);
CREATE INDEX IF NOT EXISTS index_uip_on_interaction_type ON stats.user_interaction_pairs (interaction_type);
CREATE INDEX IF NOT EXISTS index_uip_on_context ON stats.user_interaction_pairs (context_type, context_id);


-- ---------------------------------------------------------------------
-- 0bis. Périmètre utilisateurs.
--       Même base que stats.user_profile / stats.user_interactions
--       (community = 'entourage' et déjà connectés au moins une fois),
--       mais exclusion de TOUS les utilisateurs Entourage
--       (targeting_profile = 'team'), pas seulement les modérateurs :
--       contrairement à stats.user_interactions, la demande explicite
--       ici est d'exclure l'équipe entourage sans condition de rôle.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_scope_users;
CREATE TEMP TABLE tmp_scope_users AS
SELECT u.id FROM users u
WHERE
  u.community = 'entourage'
  AND u.last_sign_in_at IS NOT NULL
  AND COALESCE(u.targeting_profile, '') <> 'team';

CREATE UNIQUE INDEX ON tmp_scope_users (id);


-- ---------------------------------------------------------------------
-- 0ter. Paires d'utilisateurs bloqués (dans un sens ou dans l'autre),
--       à exclure de toutes les interactions ci-dessous.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_blocked_pairs;
CREATE TEMP TABLE tmp_blocked_pairs AS
SELECT DISTINCT
  LEAST(ubu.user_id, ubu.blocked_user_id)    AS user_id_1,
  GREATEST(ubu.user_id, ubu.blocked_user_id) AS user_id_2
FROM user_blocked_users ubu;

CREATE UNIQUE INDEX ON tmp_blocked_pairs (user_id_1, user_id_2);


-- ---------------------------------------------------------------------
-- 0quater. Messages actifs, dans le périmètre utilisateurs, restreints
--          aux contenants couverts par la règle d'échange de messages
--          (quartier / événement / conversation / bonnes ondes) — les
--          groupes communautaires et entraides (group_type IN ('group',
--          'action')) sont volontairement exclus, aussi bien de la règle
--          d'échange de messages (section 1) que de la règle de réaction
--          (section 2, qui réutilise cette même table) — cf. prompt.md.
--          Matérialisée une fois pour être réutilisée par les sections 1
--          et 2.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS tmp_context_messages;
CREATE TEMP TABLE tmp_context_messages AS
SELECT
  cm.id,
  cm.user_id,
  cm.messageable_type,
  cm.messageable_id,
  cm.ancestry,
  cm.created_at,
  CASE
    WHEN cm.messageable_type = 'Neighborhood'                          THEN 'neighborhood'
    WHEN cm.messageable_type = 'Smalltalk'                             THEN 'smalltalk'
    WHEN cm.messageable_type = 'Entourage' AND e.group_type = 'outing' THEN 'outing'
    WHEN cm.messageable_type = 'Entourage' AND e.group_type = 'conversation' THEN 'conversation'
  END AS context_kind
FROM chat_messages cm
JOIN tmp_scope_users su ON su.id = cm.user_id
LEFT JOIN entourages e ON cm.messageable_type = 'Entourage' AND e.id = cm.messageable_id
WHERE cm.status <> 'deleted'
  AND cm.message_type NOT IN ('status_update', 'auto', 'broadcast')
  AND (
    cm.messageable_type IN ('Neighborhood', 'Smalltalk')
    OR (cm.messageable_type = 'Entourage' AND e.group_type IN ('outing', 'conversation'))
  );

CREATE INDEX ON tmp_context_messages (messageable_type, messageable_id, ancestry, id);
CREATE INDEX ON tmp_context_messages (context_kind, ancestry);


-- ---------------------------------------------------------------------
-- 1. Échange de messages entre deux utilisateurs (interaction_type =
--    'echange_messages'), agrégé par paire d'utilisateurs et par
--    contenant (context_type/context_id) : occurrences = nombre de
--    paires de messages qualifiantes, first/last = bornes temporelles.
--
--    Règles structurelles par contenant (cf. demande) :
--    - quartier (neighborhood) et événement (outing) : deux commentaires
--      de même ancestry (1a/1b), OU un commentaire et la publication
--      racine qu'il commente (1a/1b) ; l'événement ajoute en plus une
--      interaction entre toutes les publications racines (1b).
--    - conversation et bonnes ondes : aucune restriction de hiérarchie,
--      deux messages de deux utilisateurs différents suffisent (1c/1d).
--    Dans tous les cas, l'écart entre les deux messages doit être
--    inférieur à 30 jours.
--
--    Les 4 règles structurelles ci-dessus sont désormais exécutées comme
--    4 INSERT indépendants (un par auto-jointure) plutôt que combinées en
--    une seule requête UNION ALL + agrégation : chaque instruction reste
--    petite et rapide à planifier/exécuter sur une base partagée, au lieu
--    d'un plan unique cumulant les 4 auto-jointures avant d'agréger.
--    Chaque INSERT agrège et filtre (paires bloquées) sur son propre
--    résultat, puis fusionne dans la table cible via
--    `ON CONFLICT ... DO UPDATE` sur la contrainte d'unicité
--    (user_id_1, user_id_2, interaction_type, context_type, context_id) :
--    si une même paire est trouvée par plusieurs règles dans le même
--    contenant (ex. un utilisateur a à la fois commenté une publication
--    ET commenté au même endroit qu'un autre commentateur), les
--    `occurrences` s'additionnent et les bornes de dates s'étendent,
--    exactement comme le faisait l'unique agrégation précédente.
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interaction_pairs WHERE interaction_type = 'echange_messages';

-- 1a/1b. Commentaires de même publication (même ancestry), quartier + événement
INSERT INTO stats.user_interaction_pairs (
  user_id_1, user_id_2, interaction_type, context_type, context_id,
  occurrences, first_interaction_at, last_interaction_at
)
SELECT
  LEAST(m1.user_id, m2.user_id),
  GREATEST(m1.user_id, m2.user_id),
  'echange_messages',
  CASE m1.context_kind WHEN 'neighborhood' THEN 'Quartier' WHEN 'outing' THEN 'Evenement' END,
  m1.messageable_id,
  COUNT(*),
  MIN(LEAST(m1.created_at, m2.created_at)),
  MAX(GREATEST(m1.created_at, m2.created_at))
FROM tmp_context_messages m1
JOIN tmp_context_messages m2
  ON m2.messageable_type = m1.messageable_type
 AND m2.messageable_id = m1.messageable_id
 AND m2.ancestry = m1.ancestry
 AND m2.id > m1.id
 AND m2.user_id <> m1.user_id
LEFT JOIN tmp_blocked_pairs bp
  ON bp.user_id_1 = LEAST(m1.user_id, m2.user_id) AND bp.user_id_2 = GREATEST(m1.user_id, m2.user_id)
WHERE m1.context_kind IN ('neighborhood', 'outing')
  AND m1.ancestry IS NOT NULL
  AND ABS(EXTRACT(EPOCH FROM (m2.created_at - m1.created_at))) <= 30 * 86400
  AND bp.user_id_1 IS NULL
GROUP BY 1, 2, 4, 5
ON CONFLICT (user_id_1, user_id_2, interaction_type, context_type, context_id) DO UPDATE SET
  occurrences = stats.user_interaction_pairs.occurrences + EXCLUDED.occurrences,
  first_interaction_at = LEAST(stats.user_interaction_pairs.first_interaction_at, EXCLUDED.first_interaction_at),
  last_interaction_at = GREATEST(stats.user_interaction_pairs.last_interaction_at, EXCLUDED.last_interaction_at);

-- 1a/1b. Commentaire <-> publication racine qu'il commente, quartier + événement
INSERT INTO stats.user_interaction_pairs (
  user_id_1, user_id_2, interaction_type, context_type, context_id,
  occurrences, first_interaction_at, last_interaction_at
)
SELECT
  LEAST(c.user_id, p.user_id),
  GREATEST(c.user_id, p.user_id),
  'echange_messages',
  CASE c.context_kind WHEN 'neighborhood' THEN 'Quartier' WHEN 'outing' THEN 'Evenement' END,
  c.messageable_id,
  COUNT(*),
  MIN(LEAST(c.created_at, p.created_at)),
  MAX(GREATEST(c.created_at, p.created_at))
FROM tmp_context_messages c
JOIN tmp_context_messages p
  ON p.messageable_type = c.messageable_type
 AND p.messageable_id = c.messageable_id
 AND p.ancestry IS NULL
 AND p.id = c.ancestry::bigint
 AND p.user_id <> c.user_id
LEFT JOIN tmp_blocked_pairs bp
  ON bp.user_id_1 = LEAST(c.user_id, p.user_id) AND bp.user_id_2 = GREATEST(c.user_id, p.user_id)
WHERE c.context_kind IN ('neighborhood', 'outing')
  AND c.ancestry IS NOT NULL
  AND ABS(EXTRACT(EPOCH FROM (c.created_at - p.created_at))) <= 30 * 86400
  AND bp.user_id_1 IS NULL
GROUP BY 1, 2, 4, 5
ON CONFLICT (user_id_1, user_id_2, interaction_type, context_type, context_id) DO UPDATE SET
  occurrences = stats.user_interaction_pairs.occurrences + EXCLUDED.occurrences,
  first_interaction_at = LEAST(stats.user_interaction_pairs.first_interaction_at, EXCLUDED.first_interaction_at),
  last_interaction_at = GREATEST(stats.user_interaction_pairs.last_interaction_at, EXCLUDED.last_interaction_at);

-- 1b. Publication <-> publication, événement uniquement
INSERT INTO stats.user_interaction_pairs (
  user_id_1, user_id_2, interaction_type, context_type, context_id,
  occurrences, first_interaction_at, last_interaction_at
)
SELECT
  LEAST(p1.user_id, p2.user_id),
  GREATEST(p1.user_id, p2.user_id),
  'echange_messages',
  'Evenement',
  p1.messageable_id,
  COUNT(*),
  MIN(LEAST(p1.created_at, p2.created_at)),
  MAX(GREATEST(p1.created_at, p2.created_at))
FROM tmp_context_messages p1
JOIN tmp_context_messages p2
  ON p2.messageable_type = p1.messageable_type
 AND p2.messageable_id = p1.messageable_id
 AND p2.ancestry IS NULL
 AND p2.id > p1.id
 AND p2.user_id <> p1.user_id
LEFT JOIN tmp_blocked_pairs bp
  ON bp.user_id_1 = LEAST(p1.user_id, p2.user_id) AND bp.user_id_2 = GREATEST(p1.user_id, p2.user_id)
WHERE p1.context_kind = 'outing'
  AND p1.ancestry IS NULL
  AND ABS(EXTRACT(EPOCH FROM (p2.created_at - p1.created_at))) <= 30 * 86400
  AND bp.user_id_1 IS NULL
GROUP BY 1, 2, 4, 5
ON CONFLICT (user_id_1, user_id_2, interaction_type, context_type, context_id) DO UPDATE SET
  occurrences = stats.user_interaction_pairs.occurrences + EXCLUDED.occurrences,
  first_interaction_at = LEAST(stats.user_interaction_pairs.first_interaction_at, EXCLUDED.first_interaction_at),
  last_interaction_at = GREATEST(stats.user_interaction_pairs.last_interaction_at, EXCLUDED.last_interaction_at);

-- 1c/1d. Conversation privée et bonnes ondes : aucune restriction de hiérarchie
INSERT INTO stats.user_interaction_pairs (
  user_id_1, user_id_2, interaction_type, context_type, context_id,
  occurrences, first_interaction_at, last_interaction_at
)
SELECT
  LEAST(m1.user_id, m2.user_id),
  GREATEST(m1.user_id, m2.user_id),
  'echange_messages',
  CASE m1.context_kind WHEN 'conversation' THEN 'Conversation' WHEN 'smalltalk' THEN 'Bonnes ondes' END,
  m1.messageable_id,
  COUNT(*),
  MIN(LEAST(m1.created_at, m2.created_at)),
  MAX(GREATEST(m1.created_at, m2.created_at))
FROM tmp_context_messages m1
JOIN tmp_context_messages m2
  ON m2.messageable_type = m1.messageable_type
 AND m2.messageable_id = m1.messageable_id
 AND m2.id > m1.id
 AND m2.user_id <> m1.user_id
LEFT JOIN tmp_blocked_pairs bp
  ON bp.user_id_1 = LEAST(m1.user_id, m2.user_id) AND bp.user_id_2 = GREATEST(m1.user_id, m2.user_id)
WHERE m1.context_kind IN ('conversation', 'smalltalk')
  AND ABS(EXTRACT(EPOCH FROM (m2.created_at - m1.created_at))) <= 30 * 86400
  AND bp.user_id_1 IS NULL
GROUP BY 1, 2, 4, 5
ON CONFLICT (user_id_1, user_id_2, interaction_type, context_type, context_id) DO UPDATE SET
  occurrences = stats.user_interaction_pairs.occurrences + EXCLUDED.occurrences,
  first_interaction_at = LEAST(stats.user_interaction_pairs.first_interaction_at, EXCLUDED.first_interaction_at),
  last_interaction_at = GREATEST(stats.user_interaction_pairs.last_interaction_at, EXCLUDED.last_interaction_at);


-- ---------------------------------------------------------------------
-- 2. Réaction d'un utilisateur sur un contenu posté par un autre
--    (interaction_type = 'reaction'). Une réaction porte toujours sur un
--    ChatMessage (publication, commentaire ou message : les trois sont
--    des lignes de chat_messages, cf. prompt.md). Réutilise
--    tmp_context_messages (section 0quater) : mêmes contenants que la
--    règle 1 (quartier / événement / conversation / bonnes ondes), donc
--    les groupes communautaires et entraides (group_type IN ('group',
--    'action')) sont exclus ici aussi, sur demande explicite. Pas de
--    contrainte de délai de 30 jours : non demandée pour cette catégorie.
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interaction_pairs WHERE interaction_type = 'reaction';

INSERT INTO stats.user_interaction_pairs (
  user_id_1, user_id_2, interaction_type, context_type, context_id,
  occurrences, first_interaction_at, last_interaction_at
)
SELECT
  LEAST(ur.user_id, cm.user_id),
  GREATEST(ur.user_id, cm.user_id),
  'reaction',
  CASE cm.context_kind
    WHEN 'neighborhood'  THEN 'Quartier'
    WHEN 'outing'        THEN 'Evenement'
    WHEN 'conversation'  THEN 'Conversation'
    WHEN 'smalltalk'     THEN 'Bonnes ondes'
  END,
  cm.messageable_id,
  COUNT(*),
  MIN(ur.created_at),
  MAX(ur.created_at)
FROM user_reactions ur
JOIN tmp_context_messages cm ON cm.id = ur.instance_id
JOIN tmp_scope_users su1 ON su1.id = ur.user_id
LEFT JOIN tmp_blocked_pairs bp
  ON bp.user_id_1 = LEAST(ur.user_id, cm.user_id) AND bp.user_id_2 = GREATEST(ur.user_id, cm.user_id)
WHERE ur.instance_type = 'ChatMessage'
  AND ur.user_id <> cm.user_id
  AND bp.user_id_1 IS NULL
GROUP BY 1, 2, 4, 5;


-- ---------------------------------------------------------------------
-- 3. Participation de différents utilisateurs à un même événement,
--    statut 'accepted' uniquement (interaction_type =
--    'participation_evenement'). Toutes les paires de participants
--    acceptés d'un même événement sont en interaction. `accepted_at` peut
--    être NULL même avec `status = 'accepted'` (constaté en préprod) :
--    on retombe alors sur `created_at`, comme dans user_interactions.sql
--    (section 5, `COALESCE(jr.requested_at, jr.created_at)`).
-- ---------------------------------------------------------------------
DELETE FROM stats.user_interaction_pairs WHERE interaction_type = 'participation_evenement';

INSERT INTO stats.user_interaction_pairs (
  user_id_1, user_id_2, interaction_type, context_type, context_id,
  occurrences, first_interaction_at, last_interaction_at
)
SELECT
  LEAST(jr1.user_id, jr2.user_id),
  GREATEST(jr1.user_id, jr2.user_id),
  'participation_evenement',
  'Evenement',
  jr1.joinable_id,
  COUNT(*),
  MIN(LEAST(COALESCE(jr1.accepted_at, jr1.created_at), COALESCE(jr2.accepted_at, jr2.created_at))),
  MAX(GREATEST(COALESCE(jr1.accepted_at, jr1.created_at), COALESCE(jr2.accepted_at, jr2.created_at)))
FROM join_requests jr1
JOIN join_requests jr2
  ON jr2.joinable_type = jr1.joinable_type
 AND jr2.joinable_id = jr1.joinable_id
 AND jr2.id > jr1.id
 AND jr2.user_id <> jr1.user_id
JOIN entourages e ON e.id = jr1.joinable_id
JOIN tmp_scope_users su1 ON su1.id = jr1.user_id
JOIN tmp_scope_users su2 ON su2.id = jr2.user_id
LEFT JOIN tmp_blocked_pairs bp
  ON bp.user_id_1 = LEAST(jr1.user_id, jr2.user_id) AND bp.user_id_2 = GREATEST(jr1.user_id, jr2.user_id)
WHERE jr1.joinable_type = 'Entourage'
  AND e.group_type = 'outing'
  AND jr1.status = 'accepted'
  AND jr2.status = 'accepted'
  AND bp.user_id_1 IS NULL
GROUP BY 1, 2, 5;


-- ---------------------------------------------------------------------
-- Fin : mise à jour des statistiques pour l'optimiseur de requêtes
-- ---------------------------------------------------------------------
ANALYZE stats.user_interaction_pairs;

-- Contrôle rapide : répartition par type d'interaction
-- SELECT interaction_type, context_type, count(*), sum(occurrences), min(first_interaction_at), max(last_interaction_at)
-- FROM stats.user_interaction_pairs
-- GROUP BY 1, 2
-- ORDER BY 1, 2;
