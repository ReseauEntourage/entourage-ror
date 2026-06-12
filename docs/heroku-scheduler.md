# Heroku Scheduler — tâches planifiées

## next_step_push (suggestions prochain pas)

| Champ | Valeur |
|---|---|
| **Command** | `bundle exec rails runner "NextStepPushSchedulerJob.perform_async"` |
| **Frequency** | Every day |
| **Time (UTC)** | `07:00` → 9h Paris (heure d'hiver) / 9h Paris (heure d'été) |

**Rôle :** Déclenche les push notifications pour les suggestions "prochain pas" en 3 batches :
1. Nouveaux utilisateurs inactifs (inscrits il y a 2–3 jours, aucune action)
2. Utilisateurs dont la suggestion courante a expiré (fenêtre 1h–25h depuis expiration)
3. Utilisateurs dormants (dernière connexion il y a 30–45 jours)

**Prérequis :** Le dyno Sidekiq doit être actif (`worker` dyno). La commande enfile le job dans la queue Sidekiq — elle ne l'exécute pas directement.

---

## Alternative : Sidekiq-Cron

Si Sidekiq-Cron est installé, préférer cette configuration (plus fiable en cas de restart dyno) :

```yaml
# config/sidekiq.yml
:schedule:
  next_step_push:
    cron: "0 7 * * *"
    class: "NextStepPushSchedulerJob"
    queue: "default"
```
