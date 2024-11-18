module SfCategorizable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :sf_categories

    validate :validate_sf_category_list!

    scope :tagged_with_sf_category, -> (sf_category) {
      tagged_with(sf_category, :any => true)
    }
  end

  def validate_sf_category_list!
    wrongs = self.sf_category_list.reject do |sf_category|
      Tag.sf_category_list.include?(sf_category)
    end

    errors.add(:sf_categories, "#{wrongs.join(', ')} n'est pas inclus dans la liste") if wrongs.any?
  end

  def sf_category
    self.sf_category_names.first
  end

  def sf_category= sf_category
    return unless sf_category.present?

    self.sf_category_list = [sf_category]
  end

  def sf_category_names
    # optimization to resolve n+1
    sf_categories.map(&:name)
  end
end
