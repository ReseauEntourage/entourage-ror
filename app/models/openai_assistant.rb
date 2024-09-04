class OpenaiAssistant < ApplicationRecord
  belongs_to :instance, polymorphic: true

  after_commit :run, on: :create

  attr_accessor :forced_matching

  def run
    OpenaiAssistantJob.perform_later(id)
  end
end
