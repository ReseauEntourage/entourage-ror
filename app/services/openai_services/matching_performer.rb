module OpenaiServices
  class MatchingPerformer < BasicPerformer
    attr_reader :user

    class MatcherCallback < Callback
    end

    def user_message
      {
        role: "user",
        content: [
          { type: "text", text: get_formatted_prompt },
          { type: "text", text: get_recommandations.to_json }
        ]
      }
    end

    def get_response_class
      MatchingResponse
    end

    private

    def handle_success(response)
      super(response)

      response.each_recommandation do |matching, score, explanation, index|
        openai_request.fetch_instance.matchings.create(
          match: matching,
          score: score,
          explanation: explanation,
          position: index
        )
      end
    end

    def user
      @user ||= instance.user
    end

    def get_formatted_prompt
      action_type = opposite_action_type = instance.class.name.camelize.downcase

      if instance.respond_to?(:action) && instance.action?
        action_type = instance.contribution? ? 'contribution' : 'solicitation'
        opposite_action_type = instance.contribution? ? 'solicitation' : 'contribution'
      end

      @configuration.prompt
        .gsub("{{action_type}}", action_type)
        .gsub("{{opposite_action_type}}", opposite_action_type)
        .gsub("{{name}}", instance.name)
        .gsub("{{description}}", instance.description)
    end

    def get_recommandations
      {
        recommandations:
          get_contributions.map { |contribution| Openai::ContributionSerializer.new(contribution).as_json } +
          get_solicitations.map { |solicitation| Openai::SolicitationSerializer.new(solicitation).as_json } +
          get_outings.map { |outing| Openai::OutingSerializer.new(outing).as_json } +
          get_pois.map { |poi| Openai::PoiSerializer.new(poi).as_json } +
          get_resources.map { |resource| Openai::ResourceSerializer.new(resource).as_json }
      }
    end

    def get_contributions
      return [] if instance.is_a?(Entourage) && instance.contribution?

      ContributionServices::Finder.new(user, Hash.new)
        .find_all
        .where("created_at > ?", @configuration.days_for_actions.days.ago)
        .limit(100)
    end

    def get_solicitations
      return [] if instance.is_a?(Entourage) && instance.solicitation?

      SolicitationServices::Finder.new(user, Hash.new)
        .find_all
        .where("created_at > ?", @configuration.days_for_actions.days.ago)
        .limit(100)
    end

    def get_outings
      OutingsServices::Finder.new(user, Hash.new)
        .find_all
        .between(Time.zone.now, @configuration.days_for_outings.days.from_now)
        .limit(100)
    end

    def get_pois
      return [] if user.is_offer_help?
      return [] if @configuration.poi_from_file

      Poi.validated.around(instance.latitude, instance.longitude, user.travel_distance).limit(300)
    end

    def get_resources
      return if @configuration.resource_from_file

      Resource.where(status: :active)
    end
  end
end
