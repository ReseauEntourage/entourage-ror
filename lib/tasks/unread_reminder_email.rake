task unread_reminder_email: :environment do
  user_ids =
    UnreadReminderEmail.join_requests_with_unread_items(
      since: 1.day.ago.midnight
    )
    .distinct.pluck(:user_id)

  user_ids.each_slice(1000) do |id_slice|
    User.where(id: id_slice).each do |user|
      UnreadReminderEmail.deliver_to(user)
    end
  end
end
