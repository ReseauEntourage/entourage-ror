class OpenaiRequest < ApplicationRecord
  belongs_to :instance, polymorphic: true

  after_commit :run, on: :create

  def instance
    instance_class.constantize.find(instance_id)
  end

  attr_accessor :forced_matching

  def run
    OpenaiRequestJob.perform_later(id)
  end
end
