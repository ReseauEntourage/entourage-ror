module UserSegmentService
  def self.at_day n, options={}
    if (options.keys & [:before, :after]).count != 1
      raise 'requires a :before or a :after option'
    end

    date, event =
      if options[:before]
        [n.days.from_now.all_day, options[:before]]
      else
        [n.days.ago.all_day, options[:after]]
      end

    user_scope =
      User
      .where(community: :entourage, deleted: false)
      .where("email <> ''")

    group_scope =
      Entourage
      .where(status: :open)

    case event
    when :registration
      user_scope.where(onboarding_sequence_start_at: date)
    when :last_session
      user_scope.where(last_sign_in_at: date)
    when :action_creation
      group_scope
      .where(
        group_type: :action,
        created_at: date,
      )
      .joins(:user)
      .merge(user_scope)
      .preload(:user)
    when :event
      reference_datetime = options[:before] ? :starts_at : :ends_at
      JoinRequest
      .accepted
      .where(({ role: options[:role] } if options.key?(:role)))
      .where(("metadata->>'previous_at' is null or metadata->>'previous_at' < requested_at::text" if options.key?(:role) && options[:role] == :participant))
      .joins(:user, :entourage)
      .merge(user_scope)
      .merge(
        group_scope
        .where(
          group_type: :outing,
        )
        .where("metadata->>'#{reference_datetime}' between ? and ?", date.begin, date.end)
      )
      .preload(:user, :joinable)
    end
  end
end
