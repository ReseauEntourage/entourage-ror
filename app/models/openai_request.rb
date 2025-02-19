class OpenaiRequest < ApplicationRecord
  belongs_to :instance, polymorphic: true

  # when adding a new module_type, it would be required to:
  # 1. create a new openai_assistant instance
  # 2. create a class that inherits from BasicPerformer. Check MatchingPerformer for example
  # 3. add this class to performer_instance method
  # 4. create a response class that inherits from BasicResponse. Check MatchingResponse for evample
  # 5. add this class to performer_response method
  enum module_type: {
    matching: 'matching'
  }

  after_commit :run, on: :create

  def fetch_instance
    instance_class.constantize.find(instance_id)
  end

  def instance_baseclass
    instance_class.constantize.base_class.find(instance_id)
  end

  def error?
    status.to_s == "error"
  end

  def assistant_link
    "https://platform.openai.com/playground/assistants?assistant=#{openai_assistant_id}"
  end

  def thread_link
    "https://platform.openai.com/threads/#{openai_thread_id}"
  end

  def response_valid?
    response_instance.valid?
  end

  def formatted_response
    response_instance.parsed_response
  end

  # add module_type case if needed
  def response_instance
    @response_instance ||= begin
      if matching?
        OpenaiServices::MatchingResponse.new(response: safe_json_parse(response))
      end
    end
  end

  # add module_type case if needed
  def performer_instance
    return OpenaiServices::MatchingPerformer.new(openai_request: self) if matching?
  end

  attr_accessor :forced_matching

  def run
    OpenaiRequestJob.perform_later(id)
  end

  def safe_json_parse json_string
    JSON.parse(json_string)
  rescue JSON::ParserError
    {}
  end
end
