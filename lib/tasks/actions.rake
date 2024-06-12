namespace :actions do
  desc "Clean deprecated actions"
  task clean_deprecated: :environment do
    Action
      .joins(:user)
      .where("users.validation_status in ('blocked', 'deleted', 'anonymized') or users.last_sign_in_at < ?", 6.months.ago)
      .update_all(status: :closed)
  end
end


