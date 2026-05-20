class EventBus
  @subscribers = Hash.new { |h, k| h[k] = [] }

  class << self
    def subscribe(event_name, handler)
      @subscribers[event_name] |= [handler]
    end

    def publish(event_name, payload = {})
      @subscribers[event_name].each do |handler|
        handler.call(payload)
      end
    end

    def reset!
      @subscribers.clear
    end
  end
end
