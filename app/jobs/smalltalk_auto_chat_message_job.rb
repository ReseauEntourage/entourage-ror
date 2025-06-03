class SmalltalkAutoChatMessageJob
  include Sidekiq::Worker

  def perform smalltalk_id, i18n_key, i18n_arg
    return unless entourage_user = User.find_entourage_user
    return unless smalltalk = Smalltalk.find_by_id(smalltalk_id)

    ChatMessage.new(
      message_type: 'auto',
      user: entourage_user,
      content: I18n.t("smalltalks.messager.#{i18n_key}") % i18n_arg,
      messageable: smalltalk
    ).save!
  end
end
