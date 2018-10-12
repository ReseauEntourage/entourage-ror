users
  id
  created_at
  first_sign_in_at (apparently only tracked since 2018-06-18)
  last_sign_in_at (apparently only tracked since 2016-08-25)
  country
  postal_code (those ending with XXX indicate that only the department is known)

sessions (each entry indicates that the user used the app on that date)
  user_id
  date (only tracked since 2018-08-23)

groups
  id
  type (action, event or conversation. conversations are private messages)
  title
  description
  created_at
  user_id (id of the user that created the group)
  country
  postal_code
  action_offer_or_demand (whether an action is an offer or a demand. null for events)
  display_category (the category declared by the user)
  category (the category assigned by the moderation team)
  author_type
  recipient_type
  outcome_reported_at
  outcome
  success_reason
  failure_reason

users_groups (indicates that a user has joined a group)
  user_id
  group_id
  created_at (date at which the user has asked to join the group)
  status (accepted or pending if the request to join the group has not yet been accepted)
  last_read_at (the date at which the user has viewed this group for the last time)

messages
  user_id
  group_id
  created_at
