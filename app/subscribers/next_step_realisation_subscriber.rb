# Closes a user's hero as soon as they do what it proposes, through any screen
# (design.md, decision 7): the next read of the hero then chooses a new one.
#
# EventBus handlers run in the after_commit of the business write: any error
# here is reported and swallowed, never raised into that write.
class NextStepRealisationSubscriber
  EVENTS = %w[
    join_request.created
    join_request.updated
    chat_message.created
    users_resource.created
    users_resource.updated
    user_smalltalk.created
  ].freeze

  # kinds of hero each record can realise
  RELEVANT_KINDS = {
    'JoinRequest' => %w[outing neighborhood action],
    'ChatMessage' => %w[action post_message],
    'UsersResource' => %w[content_path],
    'UserSmalltalk' => %w[smalltalk]
  }.freeze

  def self.register!
    EVENTS.each { |event| EventBus.subscribe(event, method(:on_record)) }
  end

  def self.on_record payload
    record = payload[:record]
    return unless record.respond_to?(:user_id) && record.user_id

    next_step = NextStep.active.find_by(user_id: record.user_id)
    return unless next_step
    return unless RELEVANT_KINDS.fetch(record.class.name, []).include?(next_step.kind)

    next_step.realise! if NextSteps::Realisation.realised?(next_step)
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error("NextStepRealisationSubscriber: #{e.class}: #{e.message}")
  end
end
