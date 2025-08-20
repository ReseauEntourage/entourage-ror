module UserServices
  module Options
    extend ActiveSupport::Concern

    OPTIONS = ["last_unclosed_action_notification_at", "goal_choice", "gender", "photo_acceptance"]
    OPTION_TYPES = {
      "photo_acceptance" => :boolean
    }

    OPTIONS.each do |option|
      define_method(option) do
        value = options[option]
        type = OPTION_TYPES[option]

        cast_value(value, type)
      end

      define_method("#{option}=") do |value|
        type = OPTION_TYPES[option]

        options[option] = cast_value(value, type)
      end

      define_method("set_#{option}_and_save") do |value|
        type = OPTION_TYPES[option]

        options[option] = cast_value(value, type)

        self.save
      end

      if OPTION_TYPES[option] == :boolean
        define_method("#{option}?") do
          cast_value(options[option], :boolean) == true
        end
      end
    end

    private

    def cast_value(value, type)
      return value unless type.present?

      case type
      when :boolean
        ActiveModel::Type::Boolean.new.cast(value)
      when :integer
        ActiveModel::Type::Integer.new.cast(value)
      when :datetime
        ActiveModel::Type::DateTime.new.cast(value)
      when :string
        ActiveModel::Type::String.new.cast(value)
      else
        value
      end
    end
  end
end
