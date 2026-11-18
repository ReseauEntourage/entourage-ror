# « Votre prochain pas » — requêtes Metabase

Requêtes de suivi du moteur de suggestions (EN-9473, change OpenSpec `add-next-step-suggestions`). Elles lisent `next_steps` (un prochain pas proposé par ligne, avec le segment de l'utilisateur au moment du choix), `next_step_interactions` (affichages, ouvertures du « pourquoi », taps), `user_segment_history` et `denorm_daily_engagements_with_type`.

**Fenêtre de 6 mois.** `next_steps` et `next_step_interactions` ne gardent que les 6 derniers mois : la tâche `next_steps:purge` (Heroku Scheduler, chaque jour) supprime ce qui est plus ancien, et les lignes d'un compte supprimé partent avec lui (design.md, décision 14). Toute requête sur une période plus longue est tronquée : pour comparer plus long, exporter les résultats avant la suppression.

## 1. Part des utilisateurs exposés qui interagissent avec une suggestion (objectif 40 %)

Exposé : un prochain pas affiché dans les 30 derniers jours. Interaction : un tap, une ouverture du « pourquoi », une suggestion réalisée ou ignorée.

```sql
WITH exposed AS (
  SELECT DISTINCT user_id FROM next_steps
  WHERE first_displayed_at >= NOW() - INTERVAL '30 days'
),
interacted AS (
  SELECT user_id FROM next_step_interactions
  WHERE kind IN ('tapped', 'why_opened') AND created_at >= NOW() - INTERVAL '30 days'
  UNION
  SELECT user_id FROM next_steps
  WHERE status IN ('realised', 'ignored') AND first_displayed_at >= NOW() - INTERVAL '30 days'
)
SELECT
  COUNT(*) AS exposed_users,
  COUNT(*) FILTER (WHERE exposed.user_id IN (SELECT user_id FROM interacted)) AS interacting_users,
  ROUND(100.0 * COUNT(*) FILTER (WHERE exposed.user_id IN (SELECT user_id FROM interacted)) / NULLIF(COUNT(*), 0), 1) AS interacting_percent
FROM exposed;
```

## 2. Issue des prochains pas, par type

```sql
SELECT
  kind,
  COUNT(*) AS proposed,
  COUNT(*) FILTER (WHERE status = 'realised') AS realised,
  COUNT(*) FILTER (WHERE status = 'ignored') AS ignored,
  COUNT(*) FILTER (WHERE status = 'expired') AS expired,
  COUNT(*) FILTER (WHERE status = 'closed') AS closed,
  ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'realised') / NULLIF(COUNT(*), 0), 1) AS realised_percent
FROM next_steps
WHERE first_displayed_at >= NOW() - INTERVAL '30 days'
  AND status <> 'active'
GROUP BY kind
ORDER BY proposed DESC;
```

## 3. Segment 14 jours après l'exposition

Pour chaque prochain pas affiché il y a plus de 14 jours, le segment de l'utilisateur au moment du choix, puis 14 jours plus tard (`user_segment_history` : `valid_to` est exclusif, c'est le premier jour de la ligne suivante). Les segments supposés (nouvel inscrit, retour, équipe) sont exclus.

```sql
SELECT
  CONCAT_WS(' / ', next_steps.segment, next_steps.sub_segment) AS segment_at_choice,
  COALESCE(CONCAT_WS(' / ', history.engagement_segment, history.engagement_sub_segment), 'non classé') AS segment_14_days_later,
  COUNT(*) AS next_steps,
  COUNT(DISTINCT next_steps.user_id) AS users
FROM next_steps
LEFT JOIN user_segment_history history
  ON history.user_id = next_steps.user_id
  AND history.valid_from <= (next_steps.first_displayed_at + INTERVAL '14 days')::date
  AND (history.valid_to IS NULL OR history.valid_to > (next_steps.first_displayed_at + INTERVAL '14 days')::date)
WHERE next_steps.segment_source = 'computed'
  AND next_steps.first_displayed_at <= NOW() - INTERVAL '14 days'
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
```

## 4. Déclencheur de 2ᵉ geste

Parmi les utilisateurs qui n'avaient qu'une seule journée d'engagement avant leur première exposition, la part qui s'engage de nouveau dans les 14 et 30 jours qui suivent.

```sql
WITH first_exposure AS (
  SELECT user_id, MIN(first_displayed_at)::date AS exposed_on
  FROM next_steps
  GROUP BY user_id
),
one_engagement_day AS (
  SELECT first_exposure.user_id, first_exposure.exposed_on
  FROM first_exposure
  INNER JOIN denorm_daily_engagements_with_type engagements
    ON engagements.user_id = first_exposure.user_id
    AND engagements.date < first_exposure.exposed_on
  GROUP BY first_exposure.user_id, first_exposure.exposed_on
  HAVING COUNT(DISTINCT engagements.date) = 1
)
SELECT
  COUNT(*) AS users_with_one_engagement_day,
  COUNT(*) FILTER (WHERE EXISTS (
    SELECT 1 FROM denorm_daily_engagements_with_type engagements
    WHERE engagements.user_id = one_engagement_day.user_id
      AND engagements.date BETWEEN one_engagement_day.exposed_on AND one_engagement_day.exposed_on + 14
  )) AS second_gesture_within_14_days,
  COUNT(*) FILTER (WHERE EXISTS (
    SELECT 1 FROM denorm_daily_engagements_with_type engagements
    WHERE engagements.user_id = one_engagement_day.user_id
      AND engagements.date BETWEEN one_engagement_day.exposed_on AND one_engagement_day.exposed_on + 30
  )) AS second_gesture_within_30_days
FROM one_engagement_day;
```
