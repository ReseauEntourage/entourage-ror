class SmalltalkAutoChatMessageJob
  include Sidekiq::Worker

  def perform smalltalk_id, i18n_key
    return unless entourage_user = User.find_entourage_user
    return unless smalltalk = Smalltalk.find_by_id(smalltalk_id)

    ChatMessage.new(
      user: entourage_user,
      content: I18n.t("smalltalks.messager.#{i18n_key}"),
      joinable: smalltalk
    )
  end
end
