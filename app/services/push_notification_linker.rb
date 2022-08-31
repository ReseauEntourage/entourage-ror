class PushNotificationLinker
  class << self
    def get object
      if object.is_a?(Neighborhood)
        {
          instance: "neighborhoods",
          id: object.id
        }
      elsif object.is_a?(User)
        {
          instance: "users",
          id: object.id
        }
      elsif object.is_a?(Poi)
        {
          instance: "pois",
          id: object.id
        }
      elsif object.is_a?(Resource)
        {
          instance: "resources",
          id: object.id
        }
      elsif object.is_a?(Partner)
        {
          instance: "partners",
          id: object.id
        }
      elsif object.is_a?(Entourage) && (object.action? || object.conversation?)
        {
          instance: "conversations",
          id: object.id
        }
      elsif object.is_a?(Entourage) && object.outing?
        {
          instance: "outings",
          id: object.id
        }
      # @deprecated
      elsif object.is_a?(Tour)
        {
          instance: "tours",
          id: object.id
        }
      else
        {}
      end
    end
  end
end
