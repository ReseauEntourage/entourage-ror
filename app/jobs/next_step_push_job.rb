class NextStepPushJob
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def self.perform_later(user_id)
    perform_async(user_id)
  end

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.nil?

    return unless NextStepServices::PushEligibility.new(user: user).eligible?

    user_next_step = NextStepServices::SuggestionSelector.new(user: user).call
    return if user_next_step.nil?

    suggestion = user_next_step.next_step_suggestion
    body = suggestion.title_for(user).truncate(100)
    extra = { type: 'next_step', deep_link: suggestion.cta_action }

    tokens = UserServices::UserApplications.new(user: user).app_tokens
    tokens.each do |token|
      NotificationJob.perform_later(0, 'Entourage', body, token.push_token, user.community.slug, extra, nil)
    end

    new_options = (user.options || {}).dup
    new_options['last_push_at'] = Time.zone.now.iso8601
    new_options['push_count_without_tap'] = (new_options['push_count_without_tap'].to_i + 1)

    if new_options['push_count_without_tap'] >= 4
      new_options['push_paused_until'] = 30.days.from_now.iso8601
      new_options['push_count_without_tap'] = 0
    end

    user.update_columns(options: new_options)
  end
end
