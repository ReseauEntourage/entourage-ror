class CategoryPoi < ApplicationRecord
  self.table_name = 'categories_pois'
  belongs_to :category
  belongs_to :poi
end
