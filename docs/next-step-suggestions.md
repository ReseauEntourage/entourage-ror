# Next Step Suggestions — Documentation technique

Système de suggestions personnalisées pour améliorer l'activation et la rétention des utilisateurs Entourage Local. Chaque utilisateur dispose à tout moment d'une suggestion unique adaptée à son profil et à son niveau d'engagement.

---

## Architecture

```
NextStepSuggestion       ← catalogue de suggestions configurables
       ↓
SuggestionSelector       ← sélectionne la suggestion adaptée à l'utilisateur
       ↓
UserNextStep             ← instance de suggestion pour un utilisateur (active / completed / dismissed)
       ↓
NextStepController       ← API mobile (show / complete / dismiss / tap_push)
       ↓
NextStepPushJob          ← push notification Sidekiq (un utilisateur)
       ↓
NextStepPushSchedulerJob ← scheduler quotidien (3 batches)
```

---

## Modèles

### `NextStepSuggestion`

Catalogue des suggestions disponibles. Géré par migration (ou futur backoffice admin).

| Colonne | Type | Description |
|---|---|---|
| `suggestion_type` | string | `first_step`, `event`, `connection`, `group`, `reengagement`, `fallback` |
| `target_profile` | string | `offer_help`, `ask_for_help`, `all` |
| `min_engagement_level` | integer | Niveau minimum requis (0–4) |
| `max_engagement_level` | integer | Niveau maximum (0–4) |
| `title_template` | string | Titre avec interpolation `%{first_name}` |
| `reason_template` | string | Explication contextuelle (peut être vide) |
| `cta_label` | string | Libellé du bouton d'action |
| `cta_action` | string | Deep link ou action |
| `priority` | integer | Plus élevé = sélectionné en premier |
| `valid_for_days` | integer | Durée de validité (défaut : 3 jours) |
| `active` | boolean | Activer / désactiver sans supprimer |

### `UserNextStep`

Historique des suggestions par utilisateur.

| Colonne | Type | Description |
|---|---|---|
| `user_id` | integer | — |
| `next_step_suggestion_id` | integer | — |
| `status` | string | `active`, `completed`, `dismissed` |
| `shown_at` | datetime | Première affichage |
| `acted_at` | datetime | Date de complétion |
| `dismissed_at` | datetime | Date de dismiss |
| `expires_at` | datetime | Expiration calculée à la création |

---

## Services

### `NextStepServices::EngagementLevel`

Calcule le niveau d'engagement de l'utilisateur à partir du nombre de `JoinRequest` acceptées.

| Niveau | Condition |
|---|---|
| `:dormant` | `last_sign_in_at < 30.days.ago` |
| `0` | 0 JoinRequest acceptée |
| `1` | ≥ 1 JoinRequest acceptée |
| `2` | ≥ 3 JoinRequests acceptées |
| `3` | ≥ 8 JoinRequests acceptées + récurrence (2+ mois sur 60 jours) |

```ruby
level = NextStepServices::EngagementLevel.new(user: user).call
# => 0, 1, 2, 3 ou :dormant
```

### `NextStepServices::SuggestionSelector`

Retourne le `UserNextStep` actif courant ou en crée un nouveau. Règles appliquées dans l'ordre :

1. Retourne le step actif non expiré s'il existe
2. Retourne `nil` si une suggestion a été complétée dans les 2 dernières heures (cooling-off)
3. Pour les dormants : sélectionne `reengagement` → fallback
4. Pour les actifs : sélectionne selon `target_profile` + `engagement_level` + `priority desc`
5. Exclut les `suggestion_type` dismissés dans les 30 derniers jours
6. Fallback garanti (`suggestion_type: 'fallback'`)

```ruby
user_next_step = NextStepServices::SuggestionSelector.new(user: user).call
# => UserNextStep ou nil (cooling-off post-complétion)
```

### `NextStepServices::PushEligibility`

Vérifie si un utilisateur peut recevoir un push. Retourne `false` si l'une des conditions suivantes est vraie :

1. Aucun device token enregistré
2. Heure hors 8h–22h (heure serveur)
3. Connecté il y a moins de 30 minutes
4. Push envoyé il y a moins de 24h (`options['last_push_at']`)
5. En période de silence (`options['push_paused_until']` dans le futur)
6. Utilisateur PI (`goal == 'ask_for_help'`) sans opt-in explicite (`options['push_enabled'] != true`)
7. Riverain avec opt-out explicite (`options['push_enabled'] == false`)

```ruby
NextStepServices::PushEligibility.new(user: user).eligible?
# => true / false
```

---

## API

Toutes les routes sont dans le namespace `api/v1`, authentification par token.

### `GET /api/v1/next_step`

Retourne la suggestion courante de l'utilisateur (crée si besoin).

**Réponse 200 :**
```json
{
  "next_step": {
    "id": 42,
    "suggestion_type": "first_step",
    "title": "Dites bonjour à un voisin aujourd'hui",
    "reason": "Vous êtes dans le quartier Bastille",
    "cta_label": "Voir comment",
    "cta_action": "entourage://events",
    "expires_at": "2026-06-15T09:00:00Z"
  }
}
```

`next_step` est `null` pendant le cooling-off post-complétion (2h).

### `PATCH /api/v1/next_step/:id/complete`

Marque la suggestion comme complétée. Déclenche le cooling-off.

### `PATCH /api/v1/next_step/:id/dismiss`

Marque la suggestion comme ignorée. Exclut ce `suggestion_type` pendant 30 jours.

### `POST /api/v1/next_step/tap_push`

Signale que l'utilisateur a tapé sur la notification push. Remet `push_count_without_tap` à 0.

### `GET /api/v1/users/me/onboarding_questions`

Retourne les 3 questions de personnalisation avec la valeur actuelle de l'utilisateur.

```json
{
  "questions": [
    { "key": "goal", "title": "Comment souhaitez-vous vous engager ?", "type": "cards", "options": [...], "current_value": "offer_help" },
    { "key": "preferred_format", "title": "Quel type d'action vous correspond ?", "type": "chips", "options": [...], "current_value": null },
    { "key": "availability", "title": "Quand êtes-vous disponible ?", "type": "chips", "options": [...], "current_value": null }
  ]
}
```

### `PATCH /api/v1/users/me/onboarding_preferences`

Sauvegarde les préférences de l'utilisateur en une requête.

```json
{
  "user": {
    "goal": "offer_help",
    "preferred_format": "events",
    "availability": { "1": ["10:00-12:00"], "6": ["14:00-18:00"] },
    "push_enabled": true
  }
}
```

| Paramètre | Stockage |
|---|---|
| `goal` | `users.goal` |
| `preferred_format` | `users.options['preferred_format']` |
| `availability` | `users.availability` (jsonb) |
| `push_enabled` | `users.options['push_enabled']` |

---

## Jobs Sidekiq

### `NextStepPushJob`

Push une notification à un utilisateur. Usage :

```ruby
NextStepPushJob.perform_async(user_id)
```

Flux interne :
1. Vérifie `PushEligibility`
2. Appelle `SuggestionSelector`
3. Envoie via `NotificationJob` (title: "Entourage", body: suggestion.title_for(user))
4. Met à jour `options` : `last_push_at`, incrémente `push_count_without_tap`
5. Si `push_count_without_tap >= 4` : pose `push_paused_until = 30.days.from_now`, remet le compteur à 0

### `NextStepPushSchedulerJob`

Scheduler quotidien. Lance les 3 batches de push :

| Batch | Cible | Condition |
|---|---|---|
| 1 — Nouveaux inactifs | Inscrits il y a 2–3 jours | Aucune JoinRequest |
| 2 — Suggestion expirée | Utilisateurs actifs | `expires_at` entre 25h et 1h dans le passé |
| 3 — Dormants | Utilisateurs dormants | `last_sign_in_at` entre 45j et 30j |

---

## Heroku Scheduler

| Champ | Valeur |
|---|---|
| **Command** | `bundle exec rails runner "NextStepPushSchedulerJob.perform_async"` |
| **Frequency** | Every day |
| **Time (UTC)** | `07:00` → 9h Paris |

**Prérequis :** dyno `worker` Sidekiq actif.

**Alternative Sidekiq-Cron :**
```yaml
# config/sidekiq.yml
:schedule:
  next_step_push:
    cron: "0 7 * * *"
    class: "NextStepPushSchedulerJob"
    queue: "default"
```

---

## Suggestions seedées

7 suggestions créées à la migration (`20260612120100_seed_next_step_suggestions`) :

| Type | Profil | Niveaux | Priorité |
|---|---|---|---|
| `first_step` | `offer_help` | 0–0 | 100 |
| `first_step` | `ask_for_help` | 0–0 | 100 |
| `event` | `all` | 1–3 | 80 |
| `connection` | `offer_help` | 1–3 | 70 |
| `group` | `all` | 2–3 | 60 |
| `reengagement` | `all` | 0–4 | 90 |
| `fallback` | `all` | 0–4 | 1 |

---

## Tests

```bash
# Suite complète next_step (119 examples)
bundle exec rspec \
  spec/controllers/api/v1/next_step_controller_spec.rb \
  spec/controllers/api/v1/next_step_flow_spec.rb \
  spec/controllers/api/v1/users/onboarding_controller_spec.rb \
  spec/services/next_step_services/ \
  spec/jobs/

# Test manuel — suggestion courante (remplacer TOKEN)
curl "http://localhost:3000/api/v1/next_step?token=TOKEN"

# Test manuel — compléter
curl -X PATCH "http://localhost:3000/api/v1/next_step/ID/complete?token=TOKEN"

# Test manuel — push job
bin/rails runner "NextStepPushJob.new.perform(User.last.id)"

# Test manuel — scheduler
bin/rails runner "NextStepPushSchedulerJob.new.perform"
```

---

## Ce qui reste à faire

- **Interface admin** `NextStepSuggestion` — gérer le catalogue de suggestions (activer/désactiver, modifier les templates, ajuster les priorités) depuis le backoffice sans migration.
