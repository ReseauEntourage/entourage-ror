-- =====================================================================
-- Script : export de stats.user_profile et stats.user_interactions
-- But    : exporter les deux tables en CSV pour analyse externe
--          (profilage / graphe).
--
-- Usage  : ce script utilise \copy, une méta-commande psql (pas une
--          instruction SQL serveur) : il doit être joué avec le client
--          psql, pas via un autre outil SQL générique.
--
--            psql "<connection string preprod ou prod>" -f db/scripts/export_stats_tables.sql
--
--          \copy transfère les données via la connexion du client, donc
--          les fichiers sont écrits localement (là où psql est lancé),
--          sans nécessiter de droits d'accès au système de fichiers du
--          serveur Postgres. Adapter les chemins de sortie ci-dessous
--          si besoin (absolus ou relatifs au dossier courant).
--
-- Partitions : stats.user_interactions est partitionnée par année sur
--          interaction_at (voir user_interactions.sql). \copy sur la
--          table parente lit automatiquement TOUTES les partitions
--          (2015 à 2035 + la partition "default") — inutile d'exporter
--          chaque partition séparément. La requête de contrôle
--          ci-dessous permet de le vérifier avant l'export.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Contrôle : liste des partitions de user_interactions et taille
--    par partition, à comparer avec le total exporté plus bas.
-- ---------------------------------------------------------------------
SELECT
  child.relname  AS partition,
  pg_size_pretty(pg_relation_size(child.oid)) AS size
FROM pg_inherits
JOIN pg_class parent ON parent.oid = pg_inherits.inhparent
JOIN pg_class child  ON child.oid  = pg_inherits.inhrelid
WHERE parent.oid = 'stats.user_interactions'::regclass
ORDER BY child.relname;


-- ---------------------------------------------------------------------
-- 1. Export de stats.user_profile (1 ligne par utilisateur)
-- ---------------------------------------------------------------------
\copy (SELECT * FROM stats.user_profile ORDER BY user_id) TO 'stats_user_profile.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')


-- ---------------------------------------------------------------------
-- 2. Export de stats.user_interactions (toutes partitions incluses,
--    la requête cible la table parente).
-- ---------------------------------------------------------------------
\copy (SELECT * FROM stats.user_interactions ORDER BY interaction_at, id) TO 'stats_user_interactions.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')


-- ---------------------------------------------------------------------
-- 3. Contrôle post-export : nombre de lignes exportées par table.
--    À comparer avec `wc -l` (ou équivalent) sur les fichiers générés
--    (en retirant 1 pour l'en-tête CSV).
-- ---------------------------------------------------------------------
SELECT 'stats.user_profile' AS table_name, count(*) FROM stats.user_profile
UNION ALL
SELECT 'stats.user_interactions', count(*) FROM stats.user_interactions;
