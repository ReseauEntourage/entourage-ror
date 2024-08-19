class LexicalTransformation < ApplicationRecord
  belongs_to :instance, polymorphic: true

  def vectorizes
    [:name, :description].each do |field|
      BertJob.perform_later(id, field)
    end
  end
end
