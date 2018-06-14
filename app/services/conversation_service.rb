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

  def self.participant_ids_from_list_uuid list_uuid
    id_list(list_uuid[7..-1].split('-'))
  end

  def self.list_uuid? uuid
    uuid.is_a?(String) && uuid.index('1_list_') == 0
  end

  def self.build_conversation participant_ids:
    conversation = Entourage.new(group_type: :conversation)
    conversation.send :set_default_attributes
    conversation.user_id = participant_ids.first
    conversation.join_requests = participant_ids.map do |participant_id|
      JoinRequest.new(joinable: conversation, user_id: participant_id, role: :participant, status: JoinRequest::ACCEPTED_STATUS)
    end
    conversation.number_of_people = participant_ids.count
    conversation.readonly!
    conversation
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
end
