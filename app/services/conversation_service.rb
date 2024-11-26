require 'digest/sha2'

module ConversationService
  # validated: false is faster but ids should be valid
  def self.uuid_for_participants participant_ids, validated: true
    list = id_list(participant_ids)
    validate_id_list!(list) unless validated == false
    uuid = "1_hash_" + id_list_digest(list)
    if Entourage.where(uuid_v2: uuid).exists?
      uuid
    else
      "1_list_" + list.join('-')
    end
  end

  # validated: false is faster but ids should be valid
  def self.hash_for_participants participant_ids, validated: true
    list = id_list(participant_ids)
    validate_id_list!(list) unless validated == false
    "1_hash_" + id_list_digest(list)
  end

  def self.list_for_participants participant_ids, validated: true
    list = id_list(participant_ids)
    validate_id_list!(list) unless validated == false
    "1_list_" + list.join('-')
  end

  def self.participant_ids_from_list_uuid list_uuid, current_user: nil
    id_list(list_uuid[7..-1].split('-')).map do |id|
      case id
      when 'moderator'
        raise unless current_user
        ModerationServices.moderator(community: current_user.community).id.to_s
      when 'me'
        raise unless current_user
        current_user.id.to_s
      else
        id
      end
    end
  end

  def self.list_uuid? uuid
    uuid.is_a?(String) && uuid.index('1_list_') == 0
  end

  def self.build_conversation participant_ids:, creator_id:
    conversation = Entourage.new(group_type: :conversation)
    conversation.send :set_default_attributes
    conversation.user_id = creator_id
    conversation.join_requests = participant_ids.map do |participant_id|
      JoinRequest.new(joinable: conversation, user_id: participant_id, role: :participant, status: JoinRequest::ACCEPTED_STATUS)
    end
    conversation.number_of_people = participant_ids.count
    conversation.uuid_v2 = list_for_participants(participant_ids, validated: false)
    conversation.readonly!
    conversation
  end

  def self.conversations_allowed? from:, to:
    !to.deleted
  end

  def self.recipients conversation:, user:
    recipients =
      if conversation.new_record?
        User.where(id: conversation.join_requests.map(&:user_id) - [user.id])
      else
        conversation.members.where.not(id: user.id).merge(JoinRequest.accepted)
      end

    recipients = recipients.select(:id, :first_name, :last_name).to_a

    # if no recipient, it must be a conversation with self
    if recipients.empty?
      recipients = [user]
    end

    recipients
  end

  private

  def self.id_list array
    array.map(&:to_s).uniq.sort
  end

  def self.validate_id_list! list
    raise ArgumentError if list.any? { |id| !valid_id?(id) }
  end

  def self.valid_id? id
    !id.empty? && id.count('^0-9') == 0
  end

  def self.id_list_digest list
    Digest::SHA256.hexdigest(list.join(','))[0, 32]
  end

  def self.unread_count_for user
    return 0 if user.nil?
    Entourage
    .where(group_type: :conversation)
    .joins(:join_requests)
    .merge(user.join_requests.accepted)
    .where("unread_messages_count > 0")
    .where("entourages.feed_updated_at > archived_at or archived_at is null")
    .distinct.count
  end
end
