class LexicalTransformation < ApplicationRecord
  belongs_to :instance, polymorphic: true

  after_save :vectorizes, :if => :name_or_description_changed?

  private

  def name_or_description_changed?
    previous_changes.slice(:name, :description).present?
  end

  def vectorizes
    previous_changes.slice(:name, :description).each do |field, value|
      BertJob.perform_later(id, field)
    end
  end
end
