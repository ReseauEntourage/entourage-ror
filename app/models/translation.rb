class Translation < ApplicationRecord
  belongs_to :instance, polymorphic: true
end
