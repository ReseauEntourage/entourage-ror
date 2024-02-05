class AddFeedUpdatedAtToGroups < ActiveRecord::Migration[4.2]
  def change
    [Entourage].each do |klass|
      add_column klass, :feed_updated_at, :datetime
      klass.reset_column_information
      max_id = klass.maximum(:id)
      next if max_id.nil?
      batch_size = 1000
      (0..(max_id / batch_size)).each do |n|
        from = n * batch_size + 1
        to = (n + 1) * batch_size
        range = from..to
        records = klass.where(id: from..to)

        last_message_at =
          ChatMessage
          .where(messageable_type: klass, messageable_id: range)
          .group(:messageable_id)
          .maximum(:created_at)

        last_request_at =
          JoinRequest
          .where(joinable_type: klass, joinable_id: range)
          .group(:joinable_id)
          .maximum('coalesce(requested_at, created_at)')

        actual_ids = (last_message_at.keys + last_request_at.keys).uniq

        ActiveRecord::Base.transaction do
          actual_ids.each do |id|
            feed_updated_at = [last_message_at[id], last_request_at[id]].compact.max
            klass.where(id: id).update_all(feed_updated_at: feed_updated_at)
          end
        end
      end
    end
  end
end
