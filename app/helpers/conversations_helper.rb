module ConversationsHelper
  def display_user_name user
    [user.first_name, user.last_name].map(&:presence).compact.join(' ')
  end

  def conversation_recipients_display_names recipients, max: 3
    count = recipients.count

    recipients = User.where(id: recipients).select(:id, :first_name, :last_name)

    recipient_names = recipients.first(max).map { |u| [UserPresenter.full_name(u), u.id] }

    if count == (max + 1)
      recipient_names.push ["1 autre personne", nil]
    elsif count > (max + 1)
      recipient_names.push ["#{count - max} autres personnes", nil]
    end

    recipient_names
  end
end
