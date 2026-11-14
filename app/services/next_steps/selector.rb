module NextSteps
  # Chooses the hero and the "others" of a user (design.md, decision 5):
  # 1. need mode: a recent open solicitation is answered first;
  # 2. segment mode: the first type of the segment's list that has a candidate,
  #    the type of the previous hero moved last for variety;
  # 3. fallbacks: the next papotage, then the Bonnes ondes.
  # Within a type, the best score wins (Score).
  class Selector
    SEGMENT_TYPES = {
      'Silencieux / À activer' => %w[action content_path],
      'Curieux' => %w[post_message],
      'Observateur' => %w[outing post_message smalltalk neighborhood],
      'Contributeur' => %w[outing neighborhood smalltalk],
      'Pilier' => %w[become_ambassador action],
      'Silencieux / Dormant' => %w[outing_nearby papotage]
    }.freeze

    DEFAULT_SEGMENT = 'Silencieux / À activer'.freeze

    # types answering a need, by section
    SOCIAL_NEED_TYPES = %w[outing neighborhood].freeze
    MATERIAL_NEED_TYPES = %w[need_contribution poi].freeze

    FALLBACK_TYPES = %w[papotage smalltalk].freeze

    OTHERS_COUNT = 3

    # strongest score component → reason code
    COMPONENT_REASONS = { distance: 'near_you', interests: 'shared_interests', popularity: 'popular' }.freeze

    Choice = Struct.new(:candidate, :type, :mode, keyword_init: true)

    attr_reader :user, :segment, :need, :now

    def initialize user, now: Time.zone.now
      @user = user
      @now = now
      @segment = EffectiveSegment.for(user)
      @need = Need.for(user, now: now)
    end

    # @param previous_kind [String, nil] kind of the previous hero, moved last for variety
    # @return [Choice, nil]
    def hero previous_kind: nil
      providers = Providers.new(user, Exclusions.new(user, placement: :hero, now: now), need: need)

      need_types.each do |type|
        candidate = providers.candidates(type).first
        return choice(candidate, type, 'need') if candidate
      end

      (segment_types(previous_kind: previous_kind) + FALLBACK_TYPES).uniq.each do |type|
        candidate = providers.candidates(type).first
        return choice(candidate, type, 'segment') if candidate
      end

      nil
    end

    # The fallbacks alone (papotage, then Bonnes ondes): used when the full
    # choice fails.
    # @return [Choice, nil]
    def fallback
      providers = Providers.new(user, Exclusions.new(user, placement: :hero, now: now))

      FALLBACK_TYPES.each do |type|
        candidate = providers.candidates(type).first
        return choice(candidate, type, 'segment') if candidate
      end

      nil
    end

    # Up to 3 suggestions, of different kinds when possible, chosen by the same
    # rules as the hero but with the exclusions of the "others".
    # @return [Array<Choice>]
    def others
      providers = Providers.new(user, Exclusions.new(user, placement: :others, now: now), need: need)
      typed = (need_types.map { |type| [type, 'need'] } + (segment_types + FALLBACK_TYPES).map { |type| [type, 'segment'] }).uniq(&:first)
      chosen = []

      # first pass: the best of each kind; second pass: fill with what is left
      [true, false].each do |one_per_kind|
        typed.each do |type, mode|
          providers.candidates(type).each do |candidate|
            break if chosen.size >= OTHERS_COUNT
            next if chosen.any? { |choice| choice.candidate.key == candidate.key }
            next if one_per_kind && chosen.any? { |choice| choice.candidate.kind == candidate.kind }
            # one date per series, whatever the type (event, papotage)
            next if candidate.series && chosen.any? { |choice| choice.candidate.series == candidate.series }

            chosen << choice(candidate, type, mode)
            break if one_per_kind
          end
        end
      end

      chosen
    end

    def segment_types previous_kind: nil
      types = SEGMENT_TYPES.fetch(segment.key) { SEGMENT_TYPES.fetch(DEFAULT_SEGMENT) }
      return types unless previous_kind

      repeated, others = types.partition { |type| Providers::KINDS.fetch(type) == previous_kind }
      others + repeated
    end

    def need_types
      return [] unless need&.sections.present?

      need.sections.include?('social') ? SOCIAL_NEED_TYPES : MATERIAL_NEED_TYPES
    end

    private

    def choice candidate, type, mode
      candidate.reason_codes = reason_codes(candidate, type, mode)

      Choice.new(candidate: candidate, type: type, mode: mode)
    end

    # At most two codes: the main reason, then the strongest score component
    # (design.md, decision 11).
    def reason_codes candidate, type, mode
      main = if mode == 'need'
        candidate.kind == 'poi' ? 'poi_for_need' : 'answers_your_need'
      else
        type_reason(candidate, type)
      end

      [main, component_reason(candidate)].compact.uniq.first(2)
    end

    def type_reason candidate, type
      case candidate.kind
      when 'outing'
        return 'papotage' if type == 'papotage'

        candidate.target.online? ? 'online_event' : 'upcoming_event'
      when 'neighborhood' then candidate.target.national? ? 'national_group' : 'local_group'
      when 'action' then candidate.target.entourage_type.to_s == 'contribution' ? 'help_offered' : 'neighbor_needs_help'
      when 'post_message' then 'group_member_message'
      when 'poi' then 'poi_for_need'
      else candidate.kind
      end
    end

    def component_reason candidate
      components = (candidate.score_components || {}).select { |_, value| value.to_f.positive? }
      return if components.empty?

      strongest, _ = components.max_by { |component, value| Score::WEIGHTS[component] * value }
      COMPONENT_REASONS[strongest]
    end
  end
end
