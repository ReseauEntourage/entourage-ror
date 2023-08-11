class Translation < ApplicationRecord
  DEFAULT_LANG = :fr
  LANGUAGES = [:fr, :en, :de, :pl, :ro, :uk, :ar]

  belongs_to :instance, polymorphic: true
end
