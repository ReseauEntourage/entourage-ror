module Translatable
  extend ActiveSupport::Concern

  included do
    has_many :translations, as: :instance
  end

  def translation field:
    translations.where(instance_field: field).first
  end
end
