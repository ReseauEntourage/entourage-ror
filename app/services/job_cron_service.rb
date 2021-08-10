module JobCronService
  def self.force_close_tours
    # Daily at 2:30 AM UTC
    CleanupService.force_close_tours
    CleanupService.remove_old_encounter_message
  end

  def self.onboarding_sequence_send_emails
    # onboarding_sequence:send_emails
    # Every 10 minutes
  end

  def self.unread_reminder_email
    # Daily at 6:00 AM UTC
      user_ids = UnreadReminderEmail.join_requests_with_unread_items(
        since: 1.day.ago.midnight
      ).distinct.pluck(:user_id)

      user_ids.each_slice(1000) do |id_slice|
        User.where(id: id_slice).each do |user|
          UnreadReminderEmail.deliver_to(user)
        end
      end
  end

  def self.onboarding_sequence_send_welcome_messages
    # onboarding_sequence:send_welcome_messages
    # Every 10 minutes
    Onboarding::ChatMessagesService.deliver_welcome_message
  end

  def self.airtable_task_export_all
    # airtable_task:export_all
    # Daily at 4:00 AM UTC, seulement les lundis des semaines paires
  end
end
