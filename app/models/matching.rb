class Matching < ApplicationRecord
  belongs_to :instance, polymorphic: true
  belongs_to :match, polymorphic: true
end
