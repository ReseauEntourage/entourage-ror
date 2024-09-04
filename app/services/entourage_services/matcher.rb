module EntourageServices
  class Matcher
    PER = 25

    attr_reader :callback, :instance, :user

    class MatcherCallback < Callback
    end

    def initialize instance:
      @callback = MatcherCallback.new
      @instance = instance
      @user = instance.user
    end

    def find_best_matches
      yield callback if block_given?

      matches = Client.new.find(instance: instance, contents: find_close_to_instance)

      return callback.on_failure.try(:call, "No matches found") unless matches["success"]

      callback.on_success.try(:call, matches)
    rescue => e
      callback.on_failure.try(:call, e.message)
    end

    def find_close_to_instance
      latitude = instance.latitude
      longitude = instance.longitude

      {
        contributions: ActiveModel::Serializer::CollectionSerializer.new(
          get_contributions,
          serializer: ::V1::Matchings::ActionSerializer,
          scope: { latitude: latitude, longitude: longitude }
        ),
        solicitations: ActiveModel::Serializer::CollectionSerializer.new(
          get_solicitations,
          serializer: ::V1::Matchings::ActionSerializer,
          scope: { latitude: latitude, longitude: longitude }
        ),
        outings: ActiveModel::Serializer::CollectionSerializer.new(
          get_outings,
          serializer: ::V1::Matchings::OutingSerializer,
          scope: { latitude: latitude, longitude: longitude }
        ),
        resources: ActiveModel::Serializer::CollectionSerializer.new(
          get_resources,
          serializer: ::V1::Matchings::ResourceSerializer
        ),
        pois: ActiveModel::Serializer::CollectionSerializer.new(
          get_pois,
          serializer: ::V1::Matchings::PoiSerializer,
          scope: { latitude: latitude, longitude: longitude }
        )
      }
    end

    def get_contributions
      ContributionServices::Finder.new(user, Hash.new).find_all.limit(PER)
    end

    def get_solicitations
      SolicitationServices::Finder.new(user, Hash.new).find_all.limit(PER)
    end

    def get_outings
      OutingsServices::Finder.new(user, Hash.new).find_all.limit(PER)
    end

    def get_resources
      Resource.where(status: :active)
    end

    def get_pois
      Poi.validated.around(instance.latitude, instance.longitude, user.travel_distance).limit(PER)
    end

    def self.parse_matching matching
      return unless matching.is_a?(Hash)
      return unless matching.key?("id")
      return unless matching.key?("type")

      klass = matching["type"].classify.constantize

      return klass.find_by_id_or_uuid(matching["id"]) if klass.respond_to?(:find_by_id_or_uuid)

      klass.find_by_id(matching["id"])
    end
  end

  class Client
    attr_reader :client, :assistant_id

    def initialize
      @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
      @assistant_id = ENV['OPENAI_API_ASSISTANT_ID']
    end

    def find instance:, contents: []
      # create new thread
      thread = client.threads.create

      # create instance message
      message = client.messages.create(thread_id: thread['id'], parameters: {
        role: "assistant",
        content: {
          instance: {
            name: instance.name,
            description: instance.description,
            uuid: instance.uuid_v2
          },
          contents: contents
        }.to_json
      })

      # run the thread
      run = client.runs.create(thread_id: thread['id'], parameters: {
        assistant_id: assistant_id,
        max_prompt_tokens: 1024,
        max_completion_tokens: 256
      })

      # wait for completion
      status_loop(thread['id'], run['id'])

      # find the message
      return { success: false } unless result = find_run_message(thread['id'], run['id'])
      return { success: false } unless result['success']

      result.merge({
        "assistant_id" => assistant_id,
        "thread_id" => thread['id'],
        "run_id" => run['id'],
      })
    end

    def status_loop thread_id, run_id
      while true do
        response = client.runs.retrieve(id: run_id, thread_id: thread_id)
        status = response['status']

        break if ['completed'].include?(status) # success
        break if ['cancelled', 'failed', 'expired'].include?(status) # error
        break if ['incomplete'].include?(status) # ???

        sleep 1 if ['queued', 'in_progress', 'cancelling'].include?(status)
      end
    end

    def find_run_message thread_id, run_id
      run_steps = client.run_steps.list(thread_id: thread_id, run_id: run_id, parameters: { order: 'asc' })

      new_message_ids = run_steps['data'].filter_map { |step|
        if step['type'] == 'message_creation'
          step.dig('step_details', "message_creation", "message_id")
        end
      }

      return unless new_message_ids.any?
      return unless message = client.messages.retrieve(id: new_message_ids.first, thread_id: thread_id)

      JSON.parse(message['content'].first['text']['value']).merge({
        "message_id" => new_message_ids.first
      })
    end
  end
end
