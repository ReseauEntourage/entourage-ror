module OpenaiServices
  class BasicPerformer
    attr_reader :configuration, :client, :callback, :assistant_id, :instance

    class BasicPerformerCallback < Callback
    end

    def initialize instance:
      @callback = BasicPerformerCallback.new

      @configuration = get_configuration

      @client = OpenAI::Client.new(access_token: @configuration.api_key)
      @assistant_id = @configuration.assistant_id

      @instance = instance
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
        max_prompt_tokens: configuration.max_prompt_tokens,
        max_completion_tokens: configuration.max_completion_tokens
      })

      # wait for completion
      status = status_loop(thread['id'], run['id'])

      return callback.on_failure.try(:call, "Failure status #{status}") unless ['completed', 'requires_action'].include?(status)

      response = get_response_class.new(response: find_run_message(thread['id'], run['id']))

      return callback.on_failure.try(:call, "Response not valid", response) unless response.valid?

      callback.on_success.try(:call, response)
    rescue => e
      callback.on_failure.try(:call, e.message, nil)
    end

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

    def find_run_message thread_id, run_id
      messages = client.messages.list(thread_id: thread_id)
      messages['data'].find { |message| message['run_id'] == run_id && message['role'] == 'assistant' }
    end

    private

    # OpenaiAssistant.find_by_version(?)
    def get_configuration
      raise NotImplementedError, "this method get_configuration has to be defined in your class"
    end

    # format: { role: string, content: { type: "text", text: string }}
    def user_message
      raise NotImplementedError, "this method user_message has to be defined in your class"
    end

    # example: MatchingResponse
    def get_response_class
      raise NotImplementedError, "this method get_response_class has to be defined in your class"
    end
  end
end
