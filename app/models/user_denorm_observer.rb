class UserDenormObserver < ActiveRecord::Observer
  # this class ensures that join_request and chat_message updates lead to denorm updates
  observe :join_request, :chat_message, :entourage

  def after_create(record)
    action(:create, record)
  end

  def after_update(record)
    action(:update, record)
  end

  def after_destroy(record)
    action(:destroy, record)
  end

  private

  # @param verb :create, :update, :destroy
  # @param record JoinRequest or ChatMessage instance
  # return sends a directive to UserDenorm to update a specific field
  def action(verb, record)
    return unless user_id = record.user_id

    denorm = UserDenorm.find_or_create_by(user_id: user_id)
    method = "#{record.class.name.underscore}_on_#{verb.to_s}".to_sym
    return unless UserDenorm.instance_methods.include?(method)

    denorm.send(method, record)
    denorm.save
  rescue => e
    # we do not want any error raising; this class should be as quiet as possible
    Rails.logger.warn "UserDenormObserver #{e.message}"
  end
end