module UserServices
  module Options
    extend ActiveSupport::Concern

    OPTIONS = ["last_unclosed_action_notification_at"]

    OPTIONS.each do |option|
      define_method(option) do
        options[option]
      end

      define_method("#{option}=") do |value|
        options[option] = value
      end
    end

    def last_unclosed_action_notification_at_and_update!
      datetime = last_unclosed_action_notification_at

      self.last_unclosed_action_notification_at = Time.zone.now
      self.save

      datetime
    end
  end
end
