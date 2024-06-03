module Concernable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :concerns

    validate :validate_concern_list!
  end

  def validate_concern_list!
    wrongs = self.concern_list.reject do |concern|
      Tag.concern_list.include?(concern)
    end

    errors.add(:concerns, "#{wrongs.join(', ')} n'est pas inclus dans la liste") if wrongs.any?
  end

  def concerns= concerns
    if concerns.is_a? Array
      self.concern_list = concerns.join(', ')
    elsif concerns.is_a? String
      self.concern_list = concerns
    end
  end

  def concern_names
    # optimization to resolve n+1
    concerns.map(&:name)
  end

  def concern_i18n
    concern_names.map { |concern| I18n.t("tags.concerns.#{concern}") }
  end
end
