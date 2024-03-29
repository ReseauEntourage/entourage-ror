# Push Notification Trigger

This class aims at configuring notifications to be sent to users.

**Notes**

 - `referent` is not sent to push notification. It is used to check whether we send notification or not (thanks to user configuration).

## neighborhoods_entourage_on_create

```ruby
# notify
sender_id: entourage.user_id,
referent: neighborhood,
instance: entourage,
users: users,
params: {
  object: neighborhood.title,
  content: CREATE_OUTING % [entity_name(neighborhood), entourage.title, to_date(entourage.starts_at)]
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "outing",
      "instance_id": "[integer]",
    },
  },
}
```

## entourage_on_create

```ruby
# notify
sender_id: @record.user_id,
referent: @record,
instance: @record,
users: [follower],
params: {
  object: @record.title,
  content: "#{partner.name} vous invite à rejoindre #{title(@record)}",
  extra: {
    type: "ENTOURAGE_INVITATION",
    entourage_id: @record.id,
    group_type: @record.group_type,
    inviter_id: user.id,
    invitee_id: follower_id,
    invitation_id: invitation_id
  }
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "outing | solicitation | contribution",
      "instance_id": "[integer]",

      "type": "ENTOURAGE_INVITATION",
      "entourage_id": "[integer]",
      "group_type": "action | outing",
      "inviter_id": "[integer]",
      "invitee_id": "[integer]",
      "invitation_id": "[integer]",
    },
  },
}
```

## outing_on_update

```ruby
# notify
sender_id: @record.user_id,
referent: @record,
instance: @record,
users: users,
params: {
  object: @record.title,
  content: update_outing_message(@record, @changes)
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "outing",
      "instance_id": "[integer]",
    },
  },
}
```

## outing_on_cancel

```ruby
# notify
sender_id: @record.user_id,
referent: @record,
instance: @record,
users: users,
params: {
  object: @record.title,
  content: CANCEL_OUTING % to_date(@record.starts_at)
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "outing",
      "instance_id": "[integer]",
    },
  },
}
```

## public_chat_message_on_create

```ruby
# notify
sender_id: @record.user_id,
referent: @record.messageable,
instance: @record.messageable,
users: users,
params: {
  object: "#{username(@record.user)} - #{title(@record.messageable)}",
  content: @record.content,
  extra: {
    group_type: group_type(@record.messageable),
    joinable_id: @record.messageable_id,
    joinable_type: @record.messageable_type,
    type: "NEW_CHAT_MESSAGE"
  }
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "solicitation | contribution",
      "instance_id": "[integer]",

      "group_type": "action",
      "joinable_id": "[integer]",
      "joinable_type": "Entourage",
      "type": "NEW_CHAT_MESSAGE"
    },
  },
}
```

## private_chat_message_on_create

```ruby
# notify
sender_id: @record.user_id,
referent: @record.messageable,
instance: @record.messageable,
users: users,
params: {
  object: username(@record.user),
  content: @record.content,
  extra: {
    group_type: group_type(@record.messageable),
    joinable_id: @record.messageable_id,
    joinable_type: @record.messageable_type,
    type: "NEW_CHAT_MESSAGE"
  }
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "conversation",
      "instance_id": "[integer]",

      "group_type": "conversation",
      "joinable_id": "[integer]",
      "joinable_type": "Entourage",
      "type": "NEW_CHAT_MESSAGE"
    },
  },
}
```

## post_on_create

```ruby
# notify
sender_id: @record.user_id,
referent: @record.messageable,
instance: @record.messageable,
users: users,
params: {
  object: title(@record.messageable),
  content: CREATE_POST % [username(@record.user), @record.content],
  extra: {
    group_type: group_type(@record.messageable),
    joinable_id: @record.messageable_id,
    joinable_type: @record.messageable_type,
    type: "NEW_CHAT_MESSAGE"
  }
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "neighborhood | outing",
      "instance_id": "[integer]",

      "group_type": "outing | nil",
      "joinable_id": "[integer]",
      "joinable_type": "Entourage | Neighborhood",
      "type": "NEW_CHAT_MESSAGE"
    },
  },
}
```

## comment_on_create

```ruby
# notify
sender_id: @record.user_id,
referent: @record.messageable,
instance: @record.parent,
users: User.where(id: user_ids),
params: {
  object: title(@record.messageable),
  content: CREATE_COMMENT % [username(@record.user), @record.content]
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "outing | neighborhood",
      "instance_id": "[integer]",
      "post_id": "[integer]",
    },
  },
}
```

## join_request_on_create

```ruby
# notify
sender_id: @record.user_id,
referent: @record.joinable,
instance: @record.user,
users: [@record.joinable.user],
params: {
  object: "Nouveau membre",
  content: content,
  extra: {
    joinable_id: @record.joinable_id,
    joinable_type: @record.joinable_type,
    group_type: group_type(@record.joinable),
    type: "JOIN_REQUEST_ACCEPTED",
    user_id: @record.user_id
  }
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "neighborhood | outing | solicitation | contribution",
      "instance_id": "[integer]",

      "joinable_id": "[integer]",
      "joinable_type": "Entourage",
      "group_type": "outing | action",
      "type": "JOIN_REQUEST_ACCEPTED",
      "user_id": "[integer]"
    },
  },
}
```

## join_request_on_update

```ruby
# notify
sender_id: @record.user_id,
referent: @record.joinable,
instance: @record.joinable,
users: [@record.user],
params: {
  object: title(@record.joinable) || "Demande acceptée",
  content: "Vous venez de rejoindre un(e) #{entity_name(@record.joinable)} de #{username(@record.joinable.user)}",
  extra: {
    joinable_id: @record.joinable_id,
    joinable_type: @record.joinable_type,
    group_type: group_type(@record.joinable),
    type: "JOIN_REQUEST_ACCEPTED",
    user_id: @record.user_id
  }
}
```

```json
{
  "sender": "[string]",
  "object": "[string]",
  "content": {
    "message": "[string]",
    "extra": {
      "instance": "neighborhood | outing | solicitation | contribution",
      "instance_id": "[integer]",

      "joinable_id": "[integer]",
      "joinable_type": "Entourage",
      "group_type": "outing | action",
      "type": "JOIN_REQUEST_ACCEPTED",
      "user_id": "[integer]"
    },
  },
}
```
