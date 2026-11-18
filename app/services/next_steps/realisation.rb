module NextSteps
  # Whether a next step is still worth showing, according to the domain data
  # (design.md, decisions 3, 6 and 7). Used at every read of the hero, and by
  # NextStepRealisationSubscriber when a related record is written.
  module Realisation
    ACTIVE_STATUSES = %w[open full].freeze

    # Has the user done what the next step proposes, through any screen?
    # A lieu solidaire is only realised by a tap (NextSteps::Current#record_interaction!).
    def self.realised? next_step
      user = next_step.user

      case next_step.kind
      when 'outing'
        joined?(user, 'Entourage', next_step.target_id)
      when 'neighborhood'
        joined?(user, 'Neighborhood', next_step.target_id)
      when 'action'
        action = next_step.target
        action.present? && Exclusions.new(user, placement: :hero).answered_action?(action)
      when 'content_path'
        UsersResource.watched.where(user_id: user.id, resource_id: next_step.target_ids).distinct.count(:resource_id) >= next_step.target_ids.size
      when 'smalltalk'
        UserSmalltalk.unscoped.where(user_id: user.id).where('created_at >= ?', next_step.first_displayed_at).exists?
      when 'post_message'
        ChatMessage.where(user_id: user.id, messageable_type: 'Neighborhood', messageable_id: next_step.target_id).exists?
      when 'become_ambassador'
        user.ambassador?
      else
        false
      end
    end

    # Has the target disappeared: event cancelled or started, entraide closed,
    # group, content or lieu removed?
    def self.target_gone? next_step, now: Time.zone.now
      case next_step.kind
      when 'outing'
        outing = next_step.target
        outing.nil? || !ACTIVE_STATUSES.include?(outing.status.to_s) || outing.starts_at.nil? || outing.starts_at <= now
      when 'action'
        action = next_step.target
        action.nil? || !ACTIVE_STATUSES.include?(action.status.to_s)
      when 'neighborhood', 'post_message'
        next_step.target.nil?
      when 'poi'
        poi = next_step.target
        poi.nil? || !poi.validated
      when 'content_path'
        next_step.resources.count < next_step.target_ids.size
      else
        false
      end
    end

    def self.joined? user, joinable_type, joinable_id
      JoinRequest
        .where(user_id: user.id, joinable_type: joinable_type, joinable_id: joinable_id, status: JoinRequest::ACCEPTED_STATUS)
        .exists?
    end
  end
end
