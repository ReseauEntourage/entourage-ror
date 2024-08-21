class LexicalTransformation < ApplicationRecord
  belongs_to :instance, polymorphic: true

  after_create :vectorizes

  def vectorizes
    BertJob.perform_later(id)
  end
end
