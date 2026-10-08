# Export des tables statistiques Entourage

Ce document accompagne trois fichiers CSV extraits de la base de données
d'Entourage, à destination d'une analyse externe (clustering, construction
d'un graphe utilisateurs, etc.) :

| Fichier                              | Contenu                                    |
|----------------------------------------|---------------------------------------------|
| `stats_user_profile.csv`                 | 1 ligne par utilisateur (profil)             |
| `stats_user_interactions.csv`              | 1 ligne par action réalisée par un utilisateur (journal d'activité) |
| `stats_user_interaction_pairs.csv`           | 1 ligne par paire d'utilisateurs ayant réellement interagi entre eux (arêtes d'un graphe social) |

**Format** : CSV avec ligne d'en-tête, encodage UTF-8, séparateur virgule.
Les valeurs vides représentent un `NULL` (aucune donnée). Les booléens sont
notés `t` (vrai) / `f` (faux).

## Comment les trois fichiers s'articulent

- `stats_user_profile.csv` donne les **nœuds** d'un graphe utilisateurs :
  qui est l'utilisateur, avec ses attributs.
- `stats_user_interactions.csv` donne un **journal d'activité** détaillé,
  action par action (une ligne = une action d'un seul utilisateur : une
  connexion, un message envoyé, un badge obtenu...).
- `stats_user_interaction_pairs.csv` donne directement les **arêtes** d'un
  graphe social : chaque ligne relie deux utilisateurs ayant réellement
  interagi entre eux (échange de messages, réaction, participation
  commune à un événement), avec un poids (`occurrences`) et une période
  (première/dernière interaction).

Le lien entre les trois fichiers se fait uniquement par la colonne
`user_id` (ou `user_id_1`/`user_id_2`) — il n'y a pas de clé technique
partagée au-delà de cette convention.

## ⚠️ À savoir avant d'exploiter les données

- **Ce sont des instantanés ("snapshots"), pas des journaux immuables.**
  Les données reflètent l'état de l'application au moment de l'export. Si
  un contenu source a été supprimé ou modifié depuis (ex : un message
  supprimé, un compte utilisateur supprimé), il peut avoir disparu ou
  changé par rapport à une extraction précédente — même si les colonnes de
  date (`interaction_at`, `created_at`...) conservent la date d'origine de
  l'événement.
- **Pas de contrainte d'intégrité référentielle.** Le lien entre les
  fichiers via `user_id` est une simple convention, pas une clé étrangère
  garantie par une base de données : un `user_id` présent dans
  `stats_user_interactions.csv` est censé exister dans
  `stats_user_profile.csv`, sans garantie technique absolue.
- Les colonnes listant des tags (`interests`, `involvements`, `concerns`,
  `badges` dans `stats_user_profile.csv`) contiennent une **liste séparée
  par des virgules à l'intérieur d'un même champ CSV** (ex.
  `sport,lecture`) — bien distinguer cette virgule interne des virgules de
  séparation de colonnes du CSV (gérées normalement par tout lecteur CSV
  respectant les guillemets).
- La colonne `availability` (`stats_user_profile.csv`) contient du **JSON
  brut sous forme de texte** (structure libre côté application).
- Aucune donnée directement identifiante n'est incluse (pas de nom,
  email, téléphone, adresse précise ni coordonnées GPS).

## `stats_user_profile.csv` — un utilisateur = une ligne

| Colonne                    | Contenu |
|-----------------------------|---------|
| `user_id`                   | Identifiant utilisateur |
| `user_type`                  | `pro` ou `public` |
| `goal`                        | Objectif déclaré (`offer_help`, `ask_for_help`, `organization`, `staff`, ou vide) |
| `targeting_profile`            | Segmentation plus fine (`asks_for_help`, `offers_help`, `partner`, `team`, `ambassador`, ou vide) — à croiser avec `goal` en cas d'ambiguïté |
| `validation_status`             | `validated`, `blocked`, `temporary_blocked`, `deleted`, `pending` |
| `deleted`                        | Compte marqué supprimé côté application |
| `is_staff`                        | Vrai si admin, manager, super-admin ou rôle modérateur — à filtrer pour exclure les comptes internes d'un clustering utilisateurs |
| `partner_id`                       | Organisation/partenaire de rattachement (surtout pour les comptes `pro`), vide sinon |
| `country`                           | Code pays de l'adresse principale de l'utilisateur (ISO 2 lettres) |
| `postal_code`                        | Code postal de l'adresse principale |
| `city`                                | Ville de l'adresse principale |
| `lang`                                 | Langue préférée (`fr` par défaut) |
| `age`                                   | Calculé depuis la date de naissance ; vide si non renseignée ou mal formée |
| `created_at`                             | Date d'inscription (ancienneté) |
| `last_sign_in_at`                         | Dernière connexion (récence), peut être vide |
| `entourages_count`                         | Nb total d'entourages (groupes+entraides+événements+conversations) créés |
| `actions_count`                              | Nb d'entraides créées |
| `outings_count`                                | Nb d'événements créés |
| `neighborhoods_count`                            | Nb de quartiers créés |
| `willing_to_engage_locally`                        | Disponibilité déclarée pour un engagement local |
| `travel_distance`                                    | Distance de déplacement acceptée (km) |
| `availability`                                         | Disponibilités déclarées (créneaux), JSON brut |
| `interests`                                              | Centres d'intérêt (tags), liste séparée par des virgules |
| `involvements`                                             | Préférences de mode d'engagement (tags), même format |
| `concerns`                                                   | Catégories d'entraide qui intéressent l'utilisateur (tags), même format |
| `orientation`                                                  | Orientation déclarée, valeur unique |
| `badges`                                                         | Badges actifs obtenus (tags), liste séparée par des virgules |

## `stats_user_interactions.csv` — un événement = une ligne

| Colonne             | Contenu |
|-----------------------|---------|
| `id`                    | Identifiant technique de la ligne |
| `user_id`                | Utilisateur à l'origine de l'interaction |
| `interaction_type`        | Type d'événement, voir table ci-dessous |
| `object_type`               | Catégorie de l'objet concerné, voir table ci-dessous |
| `object_id`                   | Identifiant de l'objet concerné (son sens dépend de `object_type`) ; peut être vide (ex. pour une connexion) |
| `interaction_at`                | Date métier de l'événement |
| `description`                     | Texte libre, format variable selon `interaction_type` (souvent des fragments `clé=valeur`) — non structuré |

### Types d'interaction (`interaction_type`)

| `interaction_type`             | `object_type`                | Ce que ça représente |
|----------------------------------|-------------------------------|------------------------|
| `connexion`                        | `Session`                      | Une connexion (≈1 ligne/heure/utilisateur) |
| `session`                            | `Session`                      | Une session applicative (1 ligne/jour/plateforme) |
| `creation_groupe`                      | `Groupe`                       | Création d'un groupe communautaire |
| `creation_entraide`                      | `Entraide`                     | Création d'une entraide |
| `creation_evenement`                       | `Evenement`                    | Création d'un événement |
| `creation_conversation`                      | `Conversation`                  | Création d'une conversation privée |
| `creation_quartier`                            | `Quartier`                      | Création d'un quartier |
| `demande_adhesion`                               | `Groupe`/`Evenement`/`Conversation`/`Quartier`/`Bonnes ondes` | Demande pour rejoindre (hors entraide), non acceptée |
| `demande_adhesion_entraide`                        | `Entraide`                       | Demande pour rejoindre une entraide, non acceptée |
| `adhesion_confirmee`                                 | idem que `demande_adhesion`        | Adhésion confirmée (hors entraide) |
| `adhesion_confirmee_entraide`                          | `Entraide`                         | Adhésion confirmée à une entraide |
| `participation_evenement`                                | `Evenement`                        | Participation confirmée à un événement |
| `message_envoye`                                           | `Conversation`/`Evenement`/`Quartier`/`Bonnes ondes` | Message envoyé (hors groupe/entraide) |
| `publication_groupe`                                         | `Groupe`                            | Message posté dans un groupe ou une entraide |
| `reaction`                                                     | `Message`                            | Réaction sur un message (`description` = clé de la réaction) |
| `blocage_utilisateur`                                            | `Utilisateur`                          | `object_id` = utilisateur bloqué |
| `invitation_envoyee`                                               | `Utilisateur`                            | `object_id` = utilisateur invité ; `description` contient l'entourage concerné |
| `suivi_partenaire`                                                   | `Partenaire`                              | Suivi d'un partenaire |
| `demande_partenariat`                                                  | `Partenaire`                                | Demande de partenariat |
| `inscription_bonnes_ondes`                                               | `Bonnes ondes`                                | Inscription au dispositif bonnes ondes |
| `match_bonnes_ondes`                                                       | `Bonnes ondes`                                  | Mise en relation obtenue |
| `reponse_sondage`                                                            | `Message`                                        | Réponse à un sondage (`object_id` = message contenant le sondage) |
| `badge_obtenu`                                                                 | `Badge`                                            | Badge obtenu (`description` = tag du badge) |
| `notification_recue`                                                             | variable (voir note ⚠️)                              | Notification reçue ; `description` contient l'expéditeur si connu |
| `visionnage_contenu_pedago`                                                        | `Contenu pédago`                                       | Ressource pédagogique visionnée ; `description` contient nom/catégorie/tag |

⚠️ **`notification_recue` est un cas particulier** : son `object_type`
reprend le nom technique de l'objet notifié (potentiellement toute entité
de l'application : `Entourage`, `ChatMessage`, `User`...), pas une valeur
fixe de la liste ci-dessus. À traiter séparément si besoin d'une
catégorisation homogène.

## `stats_user_interaction_pairs.csv` — une paire d'utilisateurs en interaction = une ligne

| Colonne                 | Contenu |
|--------------------------|---------|
| `id`                       | Identifiant technique de la ligne |
| `user_id_1`                  | Le plus petit des deux `user_id` de la paire |
| `user_id_2`                    | Le plus grand des deux `user_id` de la paire — `user_id_1 < user_id_2` toujours, une paire n'apparaît donc jamais deux fois (dans les deux sens) |
| `interaction_type`               | `echange_messages`, `reaction` ou `participation_evenement`, voir table ci-dessous |
| `context_type`                     | `Quartier`, `Evenement`, `Conversation` ou `Bonnes ondes` — le type de contenant dans lequel l'interaction a eu lieu |
| `context_id`                         | Identifiant du contenant (son sens dépend de `context_type`) |
| `occurrences`                          | Nombre d'occurrences agrégées sous cette ligne (paires de messages qualifiantes, réactions ou participations) — utilisable comme poids d'arête |
| `first_interaction_at`                   | Date de la première occurrence agrégée |
| `last_interaction_at`                      | Date de la dernière occurrence agrégée |

Pour une même paire d'utilisateurs, un même type d'interaction peut
apparaître sur plusieurs lignes si elle a eu lieu dans plusieurs contextes
(ex. deux utilisateurs actifs à la fois dans un même quartier et dans un
même événement) — additionner `occurrences` sur `(user_id_1, user_id_2)`
pour obtenir un poids global tous contextes/types confondus.

### Types d'interaction (`interaction_type`)

| `interaction_type`          | `context_type` possibles | Ce que ça représente |
|-------------------------------|-----------------------------|------------------------|
| `echange_messages`               | `Quartier`, `Evenement`, `Conversation`, `Bonnes ondes` | Échange de messages entre les deux utilisateurs (règles de rattachement différentes selon le contenant, écart maximum de 30 jours entre les deux messages qualifiants) |
| `reaction`                         | `Quartier`, `Evenement`, `Conversation`, `Bonnes ondes` | Un des deux utilisateurs a réagi à un contenu (publication, commentaire ou message) posté par l'autre |
| `participation_evenement`             | `Evenement`                | Les deux utilisateurs ont une participation acceptée au même événement |

Les groupes communautaires et les entraides sont volontairement exclus de
ce fichier (aucune interaction n'y est comptabilisée) ; on peut néanmoins
retrouver ce type d'activité dans `stats_user_interactions.csv`
(`publication_groupe`). Sont également exclus : les utilisateurs de
l'équipe Entourage, et les paires d'utilisateurs qui se sont bloqués.
