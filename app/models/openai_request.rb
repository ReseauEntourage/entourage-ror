class OpenaiRequest < ApplicationRecord
  belongs_to :instance, polymorphic: true

  after_commit :run, on: :create

  def instance
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
    matching_response.valid?
  end

  def formatted_response
    matching_response.parsed_response
  end

  def matching_response
    @matching_response ||= OpenaiServices::MatchingResponse.new(response: JSON.parse(response))
  rescue
    @matching_response ||= OpenaiServices::MatchingResponse.new(response: Hash.new)
  end

  attr_accessor :forced_matching

  def run
    OpenaiRequestJob.perform_later(id)
  end
end
