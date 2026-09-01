# Prompt ayant servi à générer user_interaction_pairs.sql

Ce document décrit la demande et la spécification qui ont permis de générer
`user_interaction_pairs.sql`, à l'issue d'une relecture de
`user_interactions.sql` (cf. `user_interactions_prompt.md`). Il permet de
régénérer ou d'adapter le script sans avoir à ré-explorer tout le schéma de
la base `entourage-back-preprod`.

## Constat de départ

`stats.user_interactions` (cf. `user_interactions_prompt.md`) est un journal
d'activité **par utilisateur** : une ligne = une action d'un seul
utilisateur (connexion, message envoyé, badge obtenu...). Il ne permet pas,
tel quel, de répondre à un besoin différent : construire un **graphe social**
où une arête relie deux utilisateurs ayant réellement interagi entre eux.
`user_interaction_pairs.sql` introduit une nouvelle table dédiée à cet usage,
`stats.user_interaction_pairs`, en complément de (et non en remplacement de)
`stats.user_interactions`.

## Demande initiale

> Une interaction est définie comme un échange de messages entre deux
> utilisateurs (les deux doivent avoir écrit au moins un message dans une
> même conversation) avec un échange de moins de 30 jours entre ces
> messages, avec :
> a. dans un groupe de voisins (neighborhood), l'échange peut avoir eu lieu
>    soit dans des commentaires d'une même publication (ancestry is not
>    null et ancestry identique) soit entre commentaire et la publication
>    auquel ce commentaire est rattaché (l'utilisateur qui a posté une
>    publication et l'utilisateur qui a commenté sa publication sont tous
>    les deux en interaction)
> b. dans un événement (un entourage avec group_type = 'outing'), l'échange
>    peut avoir eu lieu soit dans des commentaires d'une même publication
>    (même règle qu'en a.) soit aussi entre publications (les utilisateurs
>    qui ont posté une publication sont en interaction les uns avec les
>    autres)
> c. dans une conversation privée (group_type = 'conversation'), pas de
>    restriction de hiérarchie : les deux utilisateurs doivent avoir écrit
>    au moins un message, peu importe leur position dans la conversation
> d. dans une bonne onde (Smalltalk), même chose que c.
>
> Une interaction est aussi définie comme une réaction d'un utilisateur sur
> le contenu posté par un autre utilisateur (réaction à une publication, un
> commentaire ou un message).
>
> Une interaction est aussi définie comme la participation de différents
> utilisateurs à un même événement (le statut de participation doit être
> 'accepted').
>
> Exclusions : utilisateurs bloqués, utilisateurs Entourage
> (targeting_profile = 'team').
>
> Note : les adhésions à des entraides ne sont plus possibles
> (demande_adhesion_entraide, adhesion_confirmee, adhesion_confirmee_entraide)
> et ne sont donc plus à prendre en compte dans les interactions.

## Table cible

```sql
CREATE TABLE stats.user_interaction_pairs (
  id                    BIGSERIAL PRIMARY KEY,
  user_id_1             INTEGER      NOT NULL,  -- LEAST(des deux utilisateurs)
  user_id_2             INTEGER      NOT NULL,  -- GREATEST(des deux utilisateurs)
  interaction_type      VARCHAR(30)  NOT NULL,  -- echange_messages | reaction | participation_evenement
  context_type          VARCHAR(20)  NOT NULL,  -- Quartier | Evenement | Conversation | Bonnes ondes | Groupe | Entraide
  context_id            BIGINT       NOT NULL,
  occurrences           INTEGER      NOT NULL,  -- nb de paires de messages / réactions / participations agrégées
  first_interaction_at  TIMESTAMP    NOT NULL,
  last_interaction_at   TIMESTAMP    NOT NULL,
  CONSTRAINT user_interaction_pairs_ordered_pair CHECK (user_id_1 < user_id_2),
  CONSTRAINT user_interaction_pairs_uniq UNIQUE (user_id_1, user_id_2, interaction_type, context_type, context_id)
);
```

Une ligne = une paire d'utilisateurs en interaction dans un contexte donné
(un quartier, un événement...), pas un événement brut : la granularité brute
(un message, une réaction) exploserait le volume sans ajouter d'information
utile à la construction d'un graphe. `occurrences` sert de poids d'arête ;
`first_interaction_at`/`last_interaction_at` bornent la période
d'interaction.

## Filtre sur les utilisateurs

Même socle que `stats.user_profile`/`stats.user_interactions`
(`community = 'entourage'` et `last_sign_in_at IS NOT NULL`), avec une
exclusion différente de celle de `user_interactions.sql` : ici, **tous**
les utilisateurs Entourage (`targeting_profile = 'team'`) sont exclus, sans
condition de rôle — alors que `user_interactions.sql` n'exclut que les
`team` ayant le rôle `moderator`. C'est une demande explicite propre à cette
table ; `user_interactions.sql` n'a pas été aligné dessus (voir « Suites
possibles » plus bas).

En complément, une table temporaire `tmp_blocked_pairs` matérialise toutes
les paires d'utilisateurs bloqués (dans un sens ou dans l'autre, via
`user_blocked_users`), exclue de chacune des trois sections. Le blocage est
exclu quelle que soit sa date par rapport à l'interaction (une interaction
passée entre deux utilisateurs qui se sont bloqués depuis n'est pas
conservée).

## Méthode

1. Découper la règle 1 (échange de messages) en 4 requêtes indépendantes,
   une par combinaison (règle structurelle × contenant), plutôt qu'une
   seule requête générique : les règles diffèrent trop (avec/sans
   restriction d'`ancestry`, avec/sans règle publication-publication) pour
   être exprimées simplement en une seule requête paramétrée par
   `group_type`. Chacune des 4 est un `INSERT ... GROUP BY ... ON CONFLICT
   (...) DO UPDATE` indépendant sur `stats.user_interaction_pairs`
   (occurrences additionnées, bornes de dates étendues en cas de conflit),
   plutôt qu'un `UNION ALL` combiné en une seule requête agrégée : chaque
   instruction reste petite et rapide à planifier/exécuter sur une base
   partagée (demande explicite du 2026-09-01, cf. « Historique des
   ajustements »).
2. `chat_messages.ancestry` est à un seul niveau dans ce schéma (impossible
   de commenter un commentaire, cf. `ChatMessage#validate_ancestry!`) : pour
   un commentaire, `ancestry` vaut directement l'id (en texte) de la
   publication racine. La jointure commentaire → publication racine se fait
   donc par `p.id = c.ancestry::bigint`, sans récursion.
3. Matérialiser une fois dans `tmp_context_messages` les messages actifs,
   dans le périmètre utilisateurs, et restreints aux 4 contenants couverts
   par la règle 1 (quartier / événement / conversation / bonnes ondes),
   pour éviter de répéter ces filtres dans les 4 requêtes.
4. Le délai de 30 jours (règle 1) est vérifié **au niveau de la paire de
   messages qualifiante** (`ABS(EXTRACT(EPOCH FROM (m2.created_at -
   m1.created_at))) <= 30 * 86400`), pas au niveau du fil de discussion en
   entier : deux utilisateurs ayant chacun posté dans un même fil, mais à
   plus de 30 jours d'écart pour toutes les combinaisons de leurs messages
   respectifs, ne sont pas comptés en interaction sur ce fil.
5. Les réactions (règle 2) portent toujours sur un `ChatMessage`
   (`Reactionnable` n'est inclus que par ce modèle) : une publication, un
   commentaire et un message de conversation/bonnes ondes sont tous les
   trois des lignes de `chat_messages`, la règle 2 est donc satisfaite par
   une seule requête sur `user_reactions` + `tmp_context_messages` (la même
   table temporaire que la règle 1, cf. point ouvert ci-dessous), sans
   contrainte de délai (non demandée pour cette catégorie).
6. La participation à un événement (règle 3) s'appuie sur
   `join_requests.status = 'accepted'` (et non `participate_at`, qui est
   une donnée de présence effective distincte, non demandée ici) : toutes
   les paires de participants acceptés d'un même événement sont générées
   par auto-jointure sur `join_requests`. Constaté en préprod : `accepted_at`
   peut être NULL même avec `status = 'accepted'` — retombe sur
   `created_at` (`COALESCE`), même filet de sécurité que la section 5 de
   `user_interactions.sql`.
7. Exclusion des paires bloquées appliquée en toute fin de chaque section
   (`LEFT JOIN tmp_blocked_pairs ... WHERE bp.user_id_1 IS NULL`), après
   normalisation de la paire en `LEAST`/`GREATEST`.

## Groupes communautaires et entraides : exclus de toute interaction

La demande détaille la règle 1 pour 4 contenants (quartier, événement,
conversation, bonnes ondes) mais ne mentionnait pas au premier tour les
groupes communautaires (`group_type = 'group'`) ni les entraides
(`group_type = 'action'`, dont les adhésions ne sont plus possibles mais
dont l'historique de messages subsiste). Question posée et réponse retenue :
**exclure entièrement ces deux contenants de la règle d'échange de
messages** (règle 1), confirmé ensuite étendu à **toute règle
d'interaction**, y compris la réaction (règle 2) : un échange de messages ou
une réaction sur du contenu posté dans un groupe communautaire ou une
entraide n'est pas comptabilisé comme interaction. Implémenté en
restreignant `tmp_context_messages` à `Neighborhood`, `Smalltalk` et
`Entourage` avec `group_type IN ('outing', 'conversation')`, et en faisant
reposer la règle 2 sur cette même table temporaire plutôt que sur
`chat_messages` directement (avant ce changement, la règle 2 incluait par
erreur les réactions sur du contenu de groupe/entraide, avec
`context_type` = `Groupe` ou `Entraide`).

## Adhésions aux entraides : non reprises

Conformément à la demande, aucune règle d'interaction n'est dérivée de
`join_requests` pour les entraides (`demande_adhesion_entraide`,
`adhesion_confirmee_entraide`) : cette fonctionnalité n'est plus utilisable,
ces événements ne sont donc pas une interaction pertinente ici. Seule la
règle 3 (participation à un événement, `group_type = 'outing'`) s'appuie sur
`join_requests`, et uniquement sur `status = 'accepted'`.

## Point d'attention restant

- `occurrences` compte des paires de messages qualifiantes (règle 1), pas
  un nombre de messages distincts : deux utilisateurs ayant chacun posté 3
  messages mutuellement qualifiants dans un même fil comptent pour 9
  occurrences, pas 6. Pertinent comme poids d'arête relatif, mais à garder
  en tête si `occurrences` est interprété comme un nombre de messages.

## Historique des ajustements

- 2026-09-01 : script exécuté sur preprod (`entourage-backend-postgresql-preprod`,
  ~1,4s pour ~40k `chat_messages` / 37k `join_requests`). Un bug réel a été
  trouvé au passage (`join_requests.accepted_at` peut être NULL même avec
  `status = 'accepted'`, cf. point 6 ci-dessus) et corrigé. Résultat obtenu :
  2090 paires (4 catégories de contenant pour `echange_messages`, 1 pour
  `reaction`, 1 pour `participation_evenement`) ; vérifié sans fuite côté
  équipe ou paires bloquées. Sur demande explicite, la règle 1 (échange de
  messages) est ensuite passée de 4 sous-requêtes combinées en un seul
  `UNION ALL` + agrégation à 4 `INSERT ... ON CONFLICT DO UPDATE`
  indépendants sur `stats.user_interaction_pairs`, pour rester léger à
  exécuter sur une base partagée (cf. point 1 ci-dessus) — comportement
  fonctionnellement identique, revalidé sur le même jeu de données de test.
- 2026-09-01 : sur demande explicite, l'exclusion des groupes
  communautaires/entraides (`group_type IN ('group', 'action')`) est
  étendue de la règle 1 (échange de messages) à la règle 2 (réaction), qui
  réutilise désormais `tmp_context_messages` au lieu de rejoindre
  `chat_messages`/`entourages` directement (cf. « Groupes communautaires et
  entraides » ci-dessus). Par la même occasion, `user_interactions.sql` a
  été harmonisé/simplifié en conséquence (cf.
  `user_interactions_prompt.md`, historique du 2026-09-01) : exclusion de
  toute l'équipe `team` (et non plus seulement les modérateurs), et
  suppression de la distinction `_entraide` des sections 5/6.
- 2026-09-01 : création du script, à partir de la relecture de
  `user_interactions.sql` et de la définition métier ci-dessus.
