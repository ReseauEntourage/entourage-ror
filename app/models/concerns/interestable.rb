module Interestable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :interests

    validate :validate_interest_list!
  end

  def validate_interest_list!
    wrongs = self.interest_list.reject do |interest|
      Tag.interest_list.include?(interest)
    end

    errors.add(:interests, "#{wrongs.join(', ')} n'est pas inclus dans la liste") if wrongs.any?
  end

  def interests= interests
    if interests.is_a? Array
      self.interest_list = interests.join(', ')
    elsif interests.is_a? String
      self.interest_list = interests
    end
  end
end
