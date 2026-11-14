module V1
  # Serializes a suggestion for the apps (design.md, decision 8): a hero
  # (NextStep) or one of the "others" (NextSteps::Selector::Choice). The target
  # is serialized by the v1 serializer of its type, so that the apps reuse their
  # screens and deep links.
  class NextStepSerializer
    AMBASSADOR_FORM_URL = 'https://forms.example.com/devenir-animateur-entourage'.freeze

    def self.ambassador_form_url
      ENV['NEXT_STEPS_AMBASSADOR_FORM_URL'].presence || AMBASSADOR_FORM_URL
    end

    # @param item [NextStep, NextSteps::Selector::Choice, nil]
    # @param need_title [String, nil] title of the need, for the "others" chosen in need mode
    def initialize item, user:, need_title: nil
      @item = item
      @user = user
      @need_title = need_title
    end

    def as_json(*)
      return if item.nil?

      {
        id: hero? ? item.id : nil,
        kind: kind,
        mode: mode,
        placement: hero? ? 'hero' : 'others',
        target: target_json,
        targets: targets_json,
        link: kind == 'become_ambassador' ? self.class.ambassador_form_url : nil,
        reasons: NextSteps::Reasons.new(user).phrases(codes: reason_codes, target: target, need_title: need_title_for_item),
        expires_at: hero? ? item.expires_at : nil
      }
    end

    private

    attr_reader :item, :user, :need_title

    def hero?
      item.is_a?(NextStep)
    end

    def kind
      hero? ? item.kind : item.candidate.kind
    end

    def mode
      item.mode
    end

    def target
      @target = hero? ? item.target : item.candidate.target unless defined?(@target)
      @target
    end

    def target_ids
      hero? ? item.target_ids : item.candidate.target_ids
    end

    def reason_codes
      hero? ? item.reason_codes : item.candidate.reason_codes
    end

    def need_title_for_item
      return unless mode == 'need'
      return need_title unless hero?

      Solicitation.unscoped.find_by(id: item.need_id)&.title
    end

    def target_json
      return unless target

      scope = { user: user }

      case kind
      when 'outing' then V1::OutingSerializer.new(target, scope: scope).as_json
      when 'neighborhood', 'post_message' then V1::NeighborhoodSerializer.new(target, scope: scope).as_json
      when 'action' then V1::ActionSerializer.new(target, scope: scope.merge(latitude: user.latitude, longitude: user.longitude)).as_json
      when 'poi' then V1::PoiSerializer.new(target).as_json
      end
    end

    def targets_json
      return unless kind == 'content_path'

      resources = Resource.where(id: target_ids).index_by(&:id)

      target_ids.filter_map { |id| resources[id] }.map do |resource|
        V1::ResourceSerializer.new(resource, scope: { user: user, nohtml: true }).as_json
      end
    end
  end
end
