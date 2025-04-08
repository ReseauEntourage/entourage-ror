class Smalltalk < ApplicationRecord
  include Deeplinkable
  include JoinableScopable

  has_many :user_smalltalks
  has_many :chat_messages, as: :messageable, dependent: :destroy
  has_many :parent_chat_messages, -> { where(ancestry: nil) }, as: :messageable, class_name: :ChatMessage

  # @code_legacy
  def group_type
    'smalltalk'
  end

  # @code_legacy
  def group_type_config
    {
      'message_types' => ['text', 'share'],
      'roles' => ['member']
    }
  end

  def share_url
    return unless uuid_v2

    "#{ENV['MOBILE_HOST']}/app/smalltalks/#{uuid_v2}"
  end
end
