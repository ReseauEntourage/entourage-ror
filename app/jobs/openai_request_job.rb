require 'json'

class OpenaiRequestJob
  include Sidekiq::Worker

  sidekiq_options :retry => false, queue: :openai_requests

  def perform openai_request_id
    openai_request = OpenaiRequest.find(openai_request_id)

    # cancel performer whenever instance is null
    return unless openai_request.instance

    openai_request.performer_instance.perform
  end

  def self.perform_later openai_request_id
    OpenaiRequestJob.perform_async(openai_request_id)
  end
end
