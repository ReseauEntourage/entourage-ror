module MatchingServices
  class Connect
    attr_reader :client, :callback, :assistant_id, :instance, :user

    class MatcherCallback < Callback
    end

    def initialize instance:
      @callback = MatcherCallback.new

      @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
      @assistant_id = ENV['OPENAI_API_ASSISTANT_ID_2']

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
        max_prompt_tokens: 1024*16,
        max_completion_tokens: 1024
      })

      # wait for completion
      status = status_loop(thread['id'], run['id'])

      return callback.on_failure.try(:call, "Failure status #{status}") unless ['completed', 'requires_action'].include?(status)

      response = Response.new(response: find_run_message(thread['id'], run['id']))

      return callback.on_failure.try(:call, "Response not valid") unless response.valid?

      callback.on_success.try(:call, response)
    rescue => e
      callback.on_failure.try(:call, e.message)
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
      instance_class = if instance.respond_to?(:action) && instance.action?
        instance.contribution? ? 'contribution' : 'solicitation'
      else
        instance.class.name.camelize.downcase
      end

      {
        role: "user",
        content: [{
          type: "text",
          text: "I created a #{instance_class} \"#{instance.name}\" : #{instance.description}. What are the most relevant recommandations? The following text contains all the possible recommandations."
        }, {
          type: "text",
          text: get_recommandations.to_json
        }]
      }
    end

    def get_recommandations
      {
        recommandations: {
          contributions: get_contributions.pluck(:uuid_v2, :title, :description).map { |values| [:uuid_v2, :title, :description].zip(values).to_h },
          solicitations: get_solicitations.pluck(:uuid_v2, :title, :description).map { |values| [:uuid_v2, :title, :description].zip(values).to_h },
          outings: get_outings.pluck(:uuid_v2, :title, :description).map { |values| [:uuid_v2, :title, :description].zip(values).to_h }
        }
      }
    end

    def get_contributions
      return [] if instance.is_a?(Entourage) && instance.contribution?

      ContributionServices::Finder.new(user, Hash.new).find_all.limit(100)
    end

    def get_solicitations
      return [] if instance.is_a?(Entourage) && instance.solicitation?

      SolicitationServices::Finder.new(user, Hash.new).find_all.limit(100)
    end

    def get_outings
      OutingsServices::Finder.new(user, Hash.new).find_all.limit(100)
    end
  end
end
