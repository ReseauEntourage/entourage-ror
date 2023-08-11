module Translatable
  extend ActiveSupport::Concern

  included do
    has_one :translation, as: :instance
  end
end
