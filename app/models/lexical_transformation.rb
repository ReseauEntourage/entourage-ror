class LexicalTransformation < ApplicationRecord
  belongs_to :instance, polymorphic: true

  after_commit :vectorizes, on: :create

  attr_accessor :forced_matching

  def vectorizes
    BertJob.perform_later(id)
  end
end
