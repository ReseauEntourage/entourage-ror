module ConversationsHelper
  def conversation_recipients_display_names recipients, max: 3
    recipient_names =
      recipients.first(max).map { |u| UserPresenter.full_name(u) }
    if recipients.count == (max + 1)
      recipient_names.push "1 autre personne"
    elsif recipients.count > (max + 1)
      recipient_names.push "#{recipients.count - n} autres personnes"
    end

    recipient_names.to_sentence
  end
end
