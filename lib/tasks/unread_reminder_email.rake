task unread_reminder_email: :environment do
  user_ids =
    UnreadReminderEmail.join_requests_with_unread_items(
      since: 1.day.ago.midnight
    )
    .uniq.pluck(:user_id)

  users =
    User.where(id: user_ids)
        .where("admin = true or email like '%@entourage.social'")

  users.find_each do |user|
    UnreadReminderEmail.deliver_to(user)
  end
end
