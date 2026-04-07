class PushNotificationLinker
  class << self
    def get object
      return { instance: object } if object.is_a?(Symbol)
      return { instance: object } if object.is_a?(String)

      if object.is_a?(Neighborhood)
        {
          instance: 'neighborhood',
          instance_id: object.id
        }
      elsif object.is_a?(Smalltalk)
        {
          instance: 'smalltalk',
          instance_id: object.id
        }
      elsif object.is_a?(UserSmalltalk)
        {
          instance: 'user_smalltalk',
          instance_id: object.id
        }
      elsif object.is_a?(User)
        {
          instance: 'user',
          instance_id: object.id
        }
      elsif object.is_a?(Poi)
        {
          instance: 'poi',
          instance_id: object.id
        }
      elsif object.is_a?(Resource)
        {
          instance: 'resource',
          instance_id: object.id
        }
      elsif object.is_a?(Partner)
        {
          instance: 'partner',
          instance_id: object.id
        }
      elsif object.is_a?(Entourage) && object.conversation?
        {
          instance: 'conversation',
          instance_id: object.id
        }
      elsif object.is_a?(Entourage) && object.outing?
        {
          instance: 'outing',
          instance_id: object.id
        }
      elsif object.is_a?(Entourage) && object.action? && object.contribution?
        {
          instance: 'contribution',
          instance_id: object.id
        }
      elsif object.is_a?(Entourage) && object.action? && object.solicitation?
        {
          instance: 'solicitation',
          instance_id: object.id
        }
      elsif object.is_a?(ChatMessage) && action?(object.messageable)
        {
          instance: 'conversation',
          instance_id: object.messageable_id
        }
      elsif object.is_a?(ChatMessage) && outing?(object.messageable)
        {
          instance: "conversation",
          instance_id: object.messageable_id
        }
      elsif is_a_post?(object)
        {
          instance: get_post_instance_for(object.messageable),
          instance_id: object.messageable_id,
          post_id: object.id
        }
      else
        {}
      end
    end

    protected

    def is_a_post? object
      object.is_a?(ChatMessage) && (outing?(object.messageable) || object.messageable.is_a?(Neighborhood))
    end

    def outing? object
      object.is_a?(Entourage) && object.outing?
    end

    def action? object
      object.is_a?(Entourage) && object.action?
    end

    def get_post_instance_for object
      linker = PushNotificationLinker.get(object)
      return unless linker.has_key?(:instance)

      "#{linker[:instance]}_post"
    end
  end
end
