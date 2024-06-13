class ComputeUnreadMessagesCountOnJoinRequests < ActiveRecord::Migration[6.1]
  def up
    unless Rails.env.test?
      Neighborhood.all.pluck(:id) do |neighborhood_id|
        UnreadChatMessageJob.perform_later('Neighborhood', neighborhood_id)
      end
    end
  end

  def down
    JoinRequest.where(joinable_type: :Neighborhood).update_all(unread_messages_count: nil)
  end
end
