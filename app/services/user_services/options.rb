module UserServices
  module Options
    extend ActiveSupport::Concern

    OPTIONS = ["last_unclosed_action_notification_at", "goal_choice", "gender", "discovery_source", "photo_acceptance"]
    OPTION_TYPES = {
      "photo_acceptance" => :boolean
    }

    DISCOVERY_SOURCES = {
      word_of_mouth: "Bouche à oreille",
      internet: "internet",
      media: "Télévision / média",
      social: "Réseaux sociaux",
      corporate: "Sensibilisation entreprise"
    }

    included do
      validate :validate_discovery_source_format
    end

    def validate_discovery_source_format
      return if discovery_source.nil?

      unless DISCOVERY_SOURCES.keys.map(&:to_s).include?(discovery_source.to_s)
        return errors.add(:discovery_source, "should be #{DISCOVERY_SOURCES.keys.join(', ')}")
      end
    end

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
