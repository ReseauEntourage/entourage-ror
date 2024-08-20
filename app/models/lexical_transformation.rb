class LexicalTransformation < ApplicationRecord
  belongs_to :instance, polymorphic: true

  def vectorizes
    BertJob.perform_later(id)
  end
end
