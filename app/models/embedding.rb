class Embedding < ApplicationRecord
  belongs_to :embeddable, polymorphic: true
end
