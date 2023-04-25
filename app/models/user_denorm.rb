class UserDenorm < ApplicationRecord
  # observes :join_request, :chat_message, :entourage
  belongs_to :user
  belongs_to :entourage, primary_key: :last_created_action_id, optional: true
  belongs_to :join_request, primary_key: :last_join_request_id, optional: true
  belongs_to :chat_message, primary_key: :last_private_chat_message_id, optional: true
  belongs_to :chat_message, primary_key: :last_group_chat_message_id, optional: true

  # create
  def entourage_on_create entourage, group_type:
    self[:last_created_action_id] = entourage.id
  end

  alias_method :contribution_on_create, :entourage_on_create
  alias_method :solicitation_on_create, :entourage_on_create
  alias_method :outing_on_create, :entourage_on_create

  def join_request_on_create join_request, group_type:
    return unless [:pending, :accepted].include?(join_request.status.to_sym)

    self[:last_join_request_id] = join_request.id
  end

  def chat_message_on_create chat_message, group_type:
    if group_type.to_sym == :conversation
      self[:last_private_chat_message_id] = chat_message.id
    else
      self[:last_group_chat_message_id] = chat_message.id
    end
  end

  # update
  def entourage_on_update entourage, group_type:
    # return unless entourage.group_type_changed?
    return unless entourage.saved_change_to_group_type?

    recompute_last_created_action_id
    recompute_last_join_request_id # if group_type_changed? then the last_join_request_id may change
    recompute_last_group_chat_message_id # if group_type_changed? then the last_group_chat_message_id may change
    # no need to recompute_last_private_chat_message_id: we can not change to/from a conversation

    UserDenormJob.perform_later(entourage.id, nil)
  end

  alias_method :contribution_on_update, :entourage_on_update
  alias_method :solicitation_on_update, :entourage_on_update
  alias_method :outing_on_update, :entourage_on_update

  def join_request_on_update join_request, group_type:
    return unless join_request.saved_change_to_status?

    recompute_last_join_request_id
  end

  def chat_message_on_update chat_message, group_type:
  end

  # destroy
  def entourage_on_destroy entourage, group_type:
    recompute_last_created_action_id
  end

  alias_method :contribution_on_destroy, :entourage_on_destroy
  alias_method :solicitation_on_destroy, :entourage_on_destroy
  alias_method :outing_on_destroy, :entourage_on_destroy

  def join_request_on_destroy join_request, group_type:
    recompute_last_join_request_id
  end

  def chat_message_on_destroy chat_message, group_type:
    if group_type.to_sym == :conversation
      recompute_last_private_chat_message_id
    else
      recompute_last_group_chat_message_id
    end
  end

  # recompute_and_save
  def recompute_and_save
    recompute_last_created_action_id
    recompute_last_join_request_id
    recompute_last_private_chat_message_id
    recompute_last_group_chat_message_id
    save
  end

  private

  def recompute_last_created_action_id
    self[:last_created_action_id] = Entourage.select(:id)
    .where(user_id: user_id, group_type: ['action', 'outing'])
    .order('created_at desc')
    .first
    &.id
  end

  def recompute_last_join_request_id
    self[:last_join_request_id] = JoinRequest.select(:id)
    .joins("join entourages on entourages.id = join_requests.joinable_id and join_requests.joinable_type = 'Entourage'")
    .where(['join_requests.user_id = ?', user_id])
    .where(['join_requests.status IN (?)', ['pending', 'accepted']])
    .where(['entourages.group_type IN (?)', ['action', 'outing']])
    .order('join_requests.created_at desc')
    .first
    &.id
  end

  def recompute_last_private_chat_message_id
    self[:last_private_chat_message_id] = ChatMessage.select(:id)
    .joins("left join entourages on entourages.id = chat_messages.messageable_id and chat_messages.messageable_type = 'Entourage'")
    .where(['chat_messages.user_id = ?', user_id])
    .where(['entourages.group_type = ?', 'conversation'])
    .order('chat_messages.created_at desc')
    .first
    &.id
  end

  def recompute_last_group_chat_message_id
    self[:last_group_chat_message_id] = ChatMessage.select(:id)
    .joins("left join entourages on entourages.id = chat_messages.messageable_id and chat_messages.messageable_type = 'Entourage'")
    .where(['chat_messages.user_id = ?', user_id])
    .where(['entourages.group_type IN (?)', ['action', 'outing']])
    .order('chat_messages.created_at desc')
    .first
    &.id
  end
end
