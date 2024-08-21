class LexicalTransformation < ApplicationRecord
  belongs_to :instance, polymorphic: true

  after_commit :vectorizes, on: :create

  def vectorizes
    BertJob.perform_later(id)
  end
end
