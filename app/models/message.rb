class Message < ActiveRecord::Base
  validates :content, presence: true
end
