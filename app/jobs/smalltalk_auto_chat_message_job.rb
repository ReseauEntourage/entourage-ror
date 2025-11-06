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

    smalltalk.add_event!(i18n_key)
  end

  def self.cancel_jobs_for_smalltalk smalltalk_id
    Sidekiq::ScheduledSet.new.select do |job|
      job.klass == 'SmalltalkAutoChatMessageJob' && job.args.first == smalltalk_id
    end.each(&:delete)
  end
end
