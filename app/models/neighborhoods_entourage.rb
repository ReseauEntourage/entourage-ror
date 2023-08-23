class NeighborhoodsEntourage < ApplicationRecord
  belongs_to :neighborhood, required: false
  belongs_to :entourage, required: false
end
