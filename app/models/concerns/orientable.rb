module Orientable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :orientations

    validate :validate_orientation_list!
  end

  def validate_orientation_list!
    wrongs = self.orientation_list.reject do |orientation|
      Tag.orientation_list.include?(orientation)
    end

    errors.add(:orientations, "#{wrongs.join(', ')} n'est pas inclus dans la liste") if wrongs.any?
  end

  def orientation
    self.orientation_names.first
  end

  def orientation= orientation
    return unless orientation.present?

    self.orientation_list = [orientation]
  end

  def orientation_names
    # optimization to resolve n+1
    orientations.map(&:name)
  end
end
