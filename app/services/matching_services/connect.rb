module MatchingServices
  class Connect
    attr_reader :configuration, :client, :callback, :assistant_id, :instance, :user

    class MatcherCallback < Callback
    end

    def initialize instance:
      @callback = MatcherCallback.new

      @configuration = OpenaiAssistant.find_by_version(1)

      @client = OpenAI::Client.new(access_token: @configuration.api_key)
      @assistant_id = @configuration.assistant_id

      @instance = instance
      @user = instance.user
    end

    def perform
      yield callback if block_given?

      # create new thread
      thread = client.threads.create

      # create instance message
      message = client.messages.create(thread_id: thread['id'], parameters: user_message)

      # run the thread
      run = client.runs.create(thread_id: thread['id'], parameters: {
        assistant_id: assistant_id,
        max_prompt_tokens: 1024*1024,
        max_completion_tokens: 1024
      })

      # wait for completion
      status = status_loop(thread['id'], run['id'])

      return callback.on_failure.try(:call, "Failure status #{status}") unless ['completed', 'requires_action'].include?(status)

      response = Response.new(response: find_run_message(thread['id'], run['id']))

      return callback.on_failure.try(:call, "Response not valid", response) unless response.valid?

      callback.on_success.try(:call, response)
    rescue => e
      callback.on_failure.try(:call, e.message, nil)
    end

    private

    def status_loop thread_id, run_id
      status = nil

      while true do
        response = client.runs.retrieve(id: run_id, thread_id: thread_id)
        status = response['status']

        break if ['completed'].include?(status) # success
        break if ['requires_action'].include?(status) # success
        break if ['cancelled', 'failed', 'expired'].include?(status) # error
        break if ['incomplete'].include?(status) # ???

        sleep 1 if ['queued', 'in_progress', 'cancelling'].include?(status)
      end

      status
    end

    def find_run_message(thread_id, run_id)
      messages = client.messages.list(thread_id: thread_id)
      messages['data'].find { |message| message['run_id'] == run_id && message['role'] == 'assistant' }
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
        recommandations: {
          contributions: get_contributions.map { |contribution| Openai::ContributionSerializer.new(contribution).as_json },
          solicitations: get_solicitations.map { |solicitation| Openai::SolicitationSerializer.new(solicitation).as_json },
          outings: get_outings.map { |outing| Openai::OutingSerializer.new(outing).as_json },
          pois: get_pois.map { |poi| Openai::PoiSerializer.new(poi).as_json },
          resources: get_resources.map { |resource| Openai::ResourceSerializer.new(resource).as_json }
        }
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
      return if @configuration.poi_from_file

      Poi.validated.around(instance.latitude, instance.longitude, user.travel_distance).limit(300)
    end

    def get_resources
      return if @configuration.resource_from_file

      Resource.where(status: :active)
    end
  end
end
