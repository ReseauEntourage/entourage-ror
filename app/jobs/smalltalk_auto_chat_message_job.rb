class SmalltalkAutoChatMessageJob
  include Sidekiq::Worker

  INACTIVITY_DELAY = 7.days

  def perform smalltalk_id, i18n_key, i18n_arg
    return unless entourage_user = User.find_entourage_user
    return unless smalltalk = Smalltalk.find_by_id(smalltalk_id)
    return handle_inactive_smalltalk(smalltalk) if stop_auto_messages?(smalltalk)

    ChatMessage.create!(
      message_type: 'auto',
      user: entourage_user,
      content: I18n.t("smalltalks.messager.#{i18n_key}") % i18n_arg,
      messageable: smalltalk
    )
  end

  private

  def handle_inactive_smalltalk smalltalk
    inactivity_duration = Time.zone.now - smalltalk.last_active_at

    return delete_all_smalltalk_jobs(smalltalk.id) if inactivity_duration >= INACTIVITY_DELAY

    postpone_all_smalltalk_jobs(smalltalk.id, 1.day)
  end

  def postpone_all_smalltalk_jobs smalltalk_id, delay
    Sidekiq::ScheduledSet.new.each do |job|
      next unless job.klass == self.class.to_s
      next unless job.args.first == smalltalk_id

      new_time = job.at + delay
      Sidekiq::Client.push(
        'class' => self.class,
        'args' => job.args,
        'at' => new_time.to_f
      )
      job.delete
    end
  end

  def delete_all_smalltalk_jobs smalltalk_id
    Sidekiq::ScheduledSet.new.each do |job|
      next unless job.klass == self.class.to_s
      next unless job.args.first == smalltalk_id

      job.delete
    end
  end

  def stop_auto_messages? smalltalk
    return false unless last_chat_message = smalltalk.last_chat_message

    last_chat_message.auto?
  end
end
