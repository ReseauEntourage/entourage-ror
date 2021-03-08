module EntourageTask
  BATCH_SIZE=100

  def self.set_max_chat_message_created_at_in_batch
    select = 'entourages.*, max(chat_messages.created_at) as max_created_at'

    Entourage.select(select).joins(:chat_messages).group('entourages.id').find_in_batches(batch_size: BATCH_SIZE) do |entourages|
      entourages.each do |entourage|
        unless entourage.max_created_at == entourage.max_chat_message_created_at
          entourage.update_attribute(:max_chat_message_created_at, entourage.max_created_at) if entourage.max_created_at
        end
      end
    end
  end

  def self.set_max_join_request_requested_at_in_batch
    select = 'entourages.*, max(join_requests.requested_at) as max_requested_at'

    Entourage.select(select).joins(:join_requests).group('entourages.id').find_in_batches(batch_size: BATCH_SIZE) do |entourages|
      entourages.each do |entourage|
        unless entourage.max_requested_at == entourage.max_join_request_requested_at
          entourage.update_attribute(:max_join_request_requested_at, entourage.max_requested_at)
        end
      end
    end
  end
end
