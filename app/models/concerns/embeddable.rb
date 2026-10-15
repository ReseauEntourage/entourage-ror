# records that can be matching candidates: their embedding is computed lazily by EmbeddingServices::Store
module Embeddable
  extend ActiveSupport::Concern

  included do
    has_one :embedding, as: :embeddable, dependent: :delete
  end
end
