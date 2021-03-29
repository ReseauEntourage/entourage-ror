module Pins
  extend ActiveSupport::Concern

  included do
  end

  def pins= text
    self[:pins] = text.split(' ')
  end
end
