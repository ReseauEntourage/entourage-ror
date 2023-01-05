class EntourageDenormObserver < ActiveRecord::Observer
  # this class ensures that chat_message updates lead to denorm updates
  observe :chat_message

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
  # @param record ChatMessage instance
  # return sends a directive to EntourageDenorm to update a specific field
  def action(verb, record)
    return unless entourage_id = record.entourage_id
    return unless [:action, :outing].include?(Entourage.find(entourage_id).group_type.to_sym)

    denorm = EntourageDenorm.find_or_create_by(entourage_id: entourage_id)
    method = "#{record.class.name.underscore}_on_#{verb.to_s}".to_sym
    return unless EntourageDenorm.instance_methods.include?(method)

    denorm.send(method, record)
    denorm.save
  rescue => e
    # we do not want any error raising; this class should be as quiet as possible
    Rails.logger.warn "EntourageDenormObserver #{e.message}"
  end
end
