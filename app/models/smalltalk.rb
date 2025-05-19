class Smalltalk < ApplicationRecord
  include Deeplinkable
  include JoinableScopable

  enum match_format: { one: 0, many: 1 }

  has_many :user_smalltalks
  has_many :chat_messages, as: :messageable, dependent: :destroy
  has_one :last_chat_message, -> {
    select('DISTINCT ON (messageable_id, messageable_type) *').order('messageable_id, messageable_type, created_at desc')
  }, as: :messageable, class_name: 'ChatMessage'
  has_one :chat_messages_count, -> {
    select('DISTINCT ON (messageable_id, messageable_type) COUNT(*), messageable_id, messageable_type').group('messageable_id, messageable_type')
  }, as: :messageable, class_name: 'ChatMessage'
  has_many :parent_chat_messages, -> { where(ancestry: nil) }, as: :messageable, class_name: :ChatMessage

  scope :matchable, -> {
    where(match_format: UserSmalltalk.match_formats[:many])
      .where("number_of_people < ?", 5)
  }

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
