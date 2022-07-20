module Categorizable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :categories

    validate :validate_category_list!
  end

  def validate_category_list!
    wrongs = self.category_list.reject do |category|
      Tag.category_list.include?(category)
    end

    errors.add(:categories, "#{wrongs.join(', ')} n'est pas inclus dans la liste") if wrongs.any?
  end

  def category= category
    self.category_list = [category]
  end
end
