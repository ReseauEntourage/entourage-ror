module UserServices
  module Options
    extend ActiveSupport::Concern

    OPTIONS = ['last_unclosed_action_notification_at', 'goal_choice', 'gender', 'discovery_source', 'photo_acceptance', 'company', 'event']
    OPTION_TYPES = {
      'photo_acceptance' => :boolean
    }

    GENDERS = {
      female: "Femme",
      male: "Homme",
      secret: "Autre",
    }

    DISCOVERY_SOURCES = {
      newspaper: "Articles de presse",
      panel: "Affichage (panneaux, métro...)",
      social: "Réseaux sociaux",
      word_of_mouth: "Bouche à oreille",
      television: "Télévision",
      entreprise: "Partenariat entreprise (avec votre emloyeur)",
      social_event: "Événement salon",
    }

    SALESFORCE_ID_REGEX = /\A[a-zA-Z0-9]{15,18}\z/

    included do
      validate :validate_gender_format
      validate :validate_discovery_source_format
      validate :validate_company
      validate :validate_event
    end

    def validate_gender_format
      return if gender.nil?

      unless GENDERS.keys.map(&:to_s).include?(gender.to_s)
        return errors.add(:gender, "should be #{GENDERS.keys.join(', ')}")
      end
    end

    def validate_discovery_source_format
      return if discovery_source.nil?

      unless DISCOVERY_SOURCES.keys.map(&:to_s).include?(discovery_source.to_s)
        return errors.add(:discovery_source, "should be #{DISCOVERY_SOURCES.keys.join(', ')}")
      end
    end

    def validate_company
      return if company.nil?

      unless company.match?(SALESFORCE_ID_REGEX)
        errors.add(:company, "should be a salesforce id")
      end
    end

    def validate_event
      return if event.nil?

      unless event.match?(SALESFORCE_ID_REGEX)
        errors.add(:event, "should be a salesforce id")
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
