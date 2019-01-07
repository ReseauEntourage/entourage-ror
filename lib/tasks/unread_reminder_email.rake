task unread_reminder_email: :environment do
  user_ids =
    UnreadReminderEmail.join_requests_with_unread_items(
      since: 1.day.ago.midnight
    )
    .uniq.pluck(:user_id)

  users.find_each do |user|
    UnreadReminderEmail.deliver_to(user)
  end
end
