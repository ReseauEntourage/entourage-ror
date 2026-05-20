module PublishesEvents
  extend ActiveSupport::Concern

  included do
    after_commit :publish_events
  end

  private

  def publish_events
    event = if previous_changes.key?("id")
      :created
    else
      :updated
    end

    EventBus.publish("#{self.class.name.underscore}.#{event}", record: self)
  end
end
