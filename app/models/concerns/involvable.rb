module Involvable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :involvements

    validate :validate_involvement_list!
  end

  def validate_involvement_list!
    wrongs = self.involvement_list.reject do |involvement|
      Tag.involvement_list.include?(involvement)
    end

    errors.add(:involvements, "#{wrongs.join(', ')} n'est pas inclus dans la liste") if wrongs.any?
  end

  def involvements= involvements
    if involvements.is_a? Array
      self.involvement_list = involvements.join(', ')
    elsif involvements.is_a? String
      self.involvement_list = involvements
    end
  end

  def involvement_names
    # optimization to resolve n+1
    involvements.map(&:name)
  end
end
