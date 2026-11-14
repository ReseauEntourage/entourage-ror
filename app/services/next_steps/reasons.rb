module NextSteps
  # Turns the reason codes of a suggestion into the one or two sentences of
  # « Pourquoi cette suggestion ? » (design.md, decision 11), in the gentle
  # variant for a person in precarity. A sentence whose data is missing (no
  # distance for a user without location…) is left out.
  class Reasons
    TIME_ZONE = 'Europe/Paris'.freeze
    MAX = 2

    def initialize user
      @user = user
      @variant = user.is_ask_for_help? ? 'gentle' : 'default'
      @locale = I18n.available_locales.include?(user.lang&.to_sym) ? user.lang.to_sym : I18n.default_locale
    end

    # @return [Array<Hash>] [{ code:, text: }]
    def phrases codes:, target: nil, need_title: nil
      I18n.with_locale(locale) do
        codes.first(MAX).filter_map do |code|
          values = values_for(code, target, need_title)
          next unless values

          { code: code, text: I18n.t("next_steps.reasons.#{code}.#{variant}", **values) }
        end
      end
    end

    private

    attr_reader :user, :variant, :locale

    # nil when the sentence cannot be written
    def values_for code, target, need_title
      case code
      when 'answers_your_need' then need_title.present? ? { need_title: need_title } : nil
      when 'poi_for_need' then need_title.present? && target ? { need_title: need_title, category: poi_category(target) } : nil
      when 'near_you' then (distance = distance_label(target)) ? { distance: distance } : nil
      when 'shared_interests' then (labels = shared_interest_labels(target)).any? ? { interests: labels.join(I18n.t('next_steps.interests_separator')) } : nil
      when 'popular' then target.respond_to?(:number_of_people) && target.number_of_people.to_i.positive? ? { count: target.number_of_people } : nil
      when 'upcoming_event' then target.respond_to?(:starts_at) && target.starts_at ? { date: date_label(target.starts_at) } : nil
      when 'national_group' then { interest: group_interest_label(target) }
      else {}
      end
    end

    def distance_label target
      return unless target.respond_to?(:latitude) && target.latitude.present? && user.latitude.present?

      km = Geocoder::Calculations.distance_between([user.latitude, user.longitude], [target.latitude, target.longitude], units: :km)
      return I18n.t('next_steps.distance.meters', count: [(km * 1000 / 100.0).round * 100, 100].max) if km < 1

      I18n.t('next_steps.distance.kilometers', count: km.round)
    end

    def shared_interest_labels target
      return [] unless target.respond_to?(:interest_list)

      (target.interest_list & user.interest_list).first(2).map { |interest| interest_label(interest) }
    end

    def group_interest_label target
      interests = target.respond_to?(:interest_list) ? target.interest_list : []
      interest = (interests & user.interest_list).first || interests.first

      interest ? interest_label(interest) : I18n.t('next_steps.reasons.national_group.fallback_interest', default: 'vos centres d’intérêt')
    end

    def interest_label interest
      I18n.t("tags.interests.#{interest}", default: interest.to_s)
    end

    def date_label starts_at
      I18n.l(starts_at.in_time_zone(TIME_ZONE).to_date, format: '%A %-d %B')
    end

    def poi_category poi
      mapped = Providers::SECTION_POI_CATEGORIES.values.flatten
      category = poi.categories.find { |candidate| mapped.include?(candidate.id) } || poi.category

      category&.name.to_s
    end
  end
end
