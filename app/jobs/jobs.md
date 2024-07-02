# Topic

This document aims at describing the jobs used in the application. More specifically, gem migrations implies to be careful with the arguments passed to the jobs. This document aims at giving a clear view of the jobs and their arguments.

**ActiveJob** supported types are: string, integer, float, decimal, boolean, symbol, array, hash, date, time, ...

See https://edgeguides.rubyonrails.org/active_job_basics.html#supported-types-for-arguments for details

**Sidekiq** supported types are:
 - String
 - integer
 - boolean

See https://github.com/sidekiq/sidekiq/wiki/Getting-Started for details


# Main jobs

## SalesforceJob

This job aims at synchronize users with Salesforce. When a user is synchronized:
 - a "Compte App" object in SF is either created or updated
 - a "Contact" object in SF is created whenever it does not already exists and no Prospect exists

**Trigger**

Synchronize is launched whenever specific user fields are updated:
 - profile information such as name, phone, email
 - at login
 - status information (ie. user deletes her account)

**perform**

```ruby
# @param user_id integer
# @param verb string
perform(user_id, verb)
```

## Notifications

There are two scenarios that determine whether we should send a notification to the user or not:
1. during user onboarding, we launch tasks a few days after a user creation. This is handle with `Onboarding::Timeliner`
2. during the user journey, we observe user actions such as: neighborhood membership, posts, reactions to a post, etc. This is handle with `PushNotificationTriggerObserver`


## Onboarding::Timeliner

This class handles onboarding notifications. It is used to send notifications to users a few days after they have created their account.

Please note that this class is not a job: it is called from a task. We declare it here because it is related to notifications.


## PushNotificationTriggerJob

This class is called from `PushNotificationTriggerObserver`, that observes user actions to determine whether or not we should send a notification. It is used to send notifications to users during their journey.

See `PushNotificationTriggerObserver->observe` to get all tracked models. Whenever a user action has been observed, the configuration of notifications is handled asynchronously by `PushNotificationTrigger`.

**perform**

```ruby
# @param class_name string
# @param verb string
# @param id integer
# @param changes json of record_changes hash
perform(class_name, verb, id, changes)
```

## AndroidNotificationJob and IosNotificationJob

These classes are used to send notifications to Android and Ios devices, once `Onboarding::Timeliner` and `PushNotificationTrigger` have determined that a notification should be sent.

**perform**

```ruby
# @param sender nil
# @param object string
# @param content string
# @param device_ids string
# @param community string
# @param extra Hash with string or symbol values
# @param badge integer
perform(sender, object, content, device_ids, community, extra, badge)
```

## SmsSenderJob

This class is used to send sms.

```ruby
# @param phone string
# @param message string
# @param sms_type string ("invite", "welcome" or "regenerate")
perform(phone, message, sms_type)
```

## TranslatorJob

This class is used to translate a text from one language to another.

```ruby
# @param class_name string ("ChatMessage", "Entourage" or "Neighborhood")
# @param id integer
perform(class_name, id)
```

## ConversationMessageBroadcastJob

This class is used to broadcast a message to all targeted participants.

```ruby
# @param conversation_message_broadcast_id integer
# @param sender_id integer
# @param recipient_id integer
# @param content string
perform(conversation_message_broadcast_id, sender_id, recipient_id, content)
```


# Very specific jobs

## ChatMessagesPrivateJob

This class is used to send private messages to users. It ought to be used in various contexts but is currently limited to a single one: when a moderator sends an alert about a user spamming to the user who have been contacted by the spammer.

```ruby
# @param sender_id integer
# @param recipient_id integer
# @param content string
perform(sender_id, recipient_id, content)
```

## EntouragesCloserJob

Whenever a user closes her account, this job is used to close all the entourages she has created.

```ruby
# @param entourage_id integer
# @param user_status string
perform(entourage_id, user_status)
```

## ConversationMessageBroadcastDenormJob

This class is used to set `sent_recipients_count` once the conversation message broadcast ended. Be aware that this job is reschedule whenever `ConversationMessageBroadcastJob.count_jobs_for` is positive.

```ruby
# @param conversation_message_broadcast_id integer
perform(conversation_message_broadcast_id)
```


# Special case: AsyncServiceJob

This class is used to call a service asynchronously. It is used in various contexts and is not limited to a single one.

```ruby
# @param klass string
# @param symbol string
# @param args array
perform(klass, symbol, *args)
```

Concerning Rails 7 migration, this job is the most sensible one to determine whether arguments are basic types or not because it is called in very different ways.

```ruby
# a hook on mailjet sends notification to record that a user has unsuscribed from the newsletter
# app/controllers/mailjet_controller
# @param event json
AsyncService.new(MailjetService).handle_event(event.as_json)
```

```ruby
# send a notification to Soliguide that a user requested to index their POIs
# app/controllers/api/v1/pois_controller
# @param query_params hash
AsyncService.new(PoiServices::SoliguideIndex).post_only_query(soliguide.query_params)
```

```ruby
# send a notification to Soliguide that a user requested to show their POIs
# app/controllers/api/v1/pois_controller
# @param id string
AsyncService.new(PoiServices::SoliguideShow).get(params[:id][1..])
```

```ruby
# app/models/email_preference
# @param id integer
AsyncService.new(self.class).sync_newsletter(self.id)
```

```ruby
# app/models/concerns/actionable
# @param self Entourage instance
AsyncService.new(FollowingService).on_create_entourage(self)
```

```ruby
# app/services/digest_email_service
# @param email DigestEmail
AsyncService.new(self).deliver(email)
```

```ruby
# app/services/sensitive_words_service
# @param self Entourage instance
AsyncService.new(SensitiveWordsService).analyze_entourage(self)
```

```ruby
# record invitations when users follow a partner; PushNotificationTrigger will then be in charge of sending the notifications
# app/services/entourage_services/entourage_builder
# @param entourage Entourage instance
AsyncService.new(FollowingService).on_create_entourage(entourage)
```

```ruby
# app/services/entourage_services/geocoding_service
# @param self Entourage instance
AsyncService.new(GeocodingService).geocode(self)
```

```ruby
# Notify Slack on Entourage creation
# app/services/experimental/entourage_slack
# @param self Entourage instance
AsyncService.new(Experimental::EntourageSlack).notify(self)
```

```ruby
# set the user's address from Google Place details
# app/services/user_services/address_service
# @param address Address instance
AsyncService.new(self.class).update_with_google_place_details(address)
```

```ruby
# app/uploaders/partner_logo_uploader
# @param previous_logo string
AsyncService.new(self).delete_s3_object_with_public_url(previous_logo)
```


# Jobs that are not used anymore

Some of the previous jobs are not used anymore or should be deprecated. They are listed below:

- `AsyncService.new(IraiserWebhookService).handle_notification(raw_headers, request.raw_post)`
- `AsyncService.new(self).set(wait_until: join_request.created_at + 15.seconds).accept_now(join_request)`
