module UserServices
  module Options
    extend ActiveSupport::Concern

    OPTIONS = ["last_unclosed_action_notification_at", "goal_choice", "gender"]

    OPTIONS.each do |option|
      define_method(option) do
        options[option]
      end

      define_method("#{option}=") do |value|
        options[option] = value
      end

      define_method("set_#{option}_and_save") do |value|
        options[option] = value

        self.save
      end
    end
  end
end
