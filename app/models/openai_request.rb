class OpenaiRequest < ApplicationRecord
  belongs_to :instance, polymorphic: true

  after_commit :run, on: :create

  attr_accessor :forced_matching

  def run
    OpenaiRequestJob.perform_later(id)
  end
end
