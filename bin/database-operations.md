
# Import db locally

## dump

```bash
pg_dump [db_connection]
  --exclude-table-data=stats.*
  --exclude-table-data=email_deliveries
  --exclude-table-data=rpush_notifications
  --exclude-table-data=session_histories
  --exclude-table-data=user_applications
  --exclude-table-data=events
  --exclude-table-data=tour_points
  --exclude-table-data=sms_deliveries
  --exclude-table-data=entourage_displays
  --exclude-table-data=rpush_feedback
  --exclude-table-data=simplified_tour_points
  --exclude-table-data=email_preferences
  --exclude-table-data=sensitive_words_checks
  --exclude-table-data=newsletter_subscriptions
  --exclude-table-data=experimental_pending_request_reminders
  --exclude-table-data=login_histories
  --exclude-table-data=user_relationships
  --exclude-table-data=entourage_scores
  --exclude-table-data=atd_users
  --exclude-table-data=tours_user
  --exclude-table-data=coordination
  --exclude-table-data=suggestion_compute_histories
  --exclude-table-data=messages
  --exclude-table-data=active_admin_comments
  --exclude-table-data=atd_synchronizations
  --exclude-table-data=questions
> database.sql;
```

## restore

```bash
postgres -Upostgres
```

```sql
drop database "entourage-dev";
create database "entourage-dev";
```

```bash
psql -Upostgres -d entourage-dev -f database.sql
```
