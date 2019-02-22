namespace :db do
  task :stats do
    connection = ActiveRecord::Base.connection
    counts = {}

    connection.tables.map do |table|
      result = ActiveRecord::Base.connection.execute("select count(*) from #{table}")
      counts[table] = result.entries.first['count'].to_i
      result.clear
    end

    counts.sort_by(&:last).each do |table, count|
      puts "#{table}: #{count}"
    end
  end

  task strip: :environment do
    unless Rails.env.development?
      abort "This command can only be run in the development environment!"
    end

    User.update_all(address_id: nil)

    [
      Address, Answer, AtdSynchronization, AtdUser,
      AuthenticationProvider, EmailDelivery, Encounter, EntourageDisplay,
      EntourageModeration, EntourageScore, Experimental::PendingRequestReminder,
      LoginHistory, Message, ModeratorRead, NewsletterSubscription,
      Organization, Partner, Question, RegistrationRequest,
      Rpush::Apns::Feedback, Rpush::App, Rpush::Notification, SensitiveWord,
      SensitiveWordsCheck, SessionHistory, SimplifiedTourPoint,
      StoreDailyReport, SuggestionComputeHistory, Tour, TourPoint,
      UserApplication, UserModeration, UserNewsfeed, UserPartner,
      UserRelationship, UsersAppetence
    ].each(&:delete_all)

    [
      :active_admin_comments, :coordination, :entourages_users, :tours_users,
      :marketing_referers
    ].each do|table|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}").clear
    end


    time_limit = 30.days.ago.midnight

    Entourage.where.not(community: :entourage).delete_all
    Entourage.where("created_at < ?", time_limit).delete_all
    Entourage.where.not(group_type: [:action, :outing]).delete_all

    JoinRequest.where.not(joinable_type: :Entourage).delete_all
    JoinRequest
      .joins("left join entourages on entourages.id = joinable_id")
      .where("entourages is null")
      .delete_all

    EntourageInvitation.where.not(invitable_type: :Entourage).delete_all
    EntourageInvitation
      .joins("left join entourages on entourages.id = invitable_id")
      .where("entourages is null")
      .delete_all

    ChatMessage.where.not(messageable_type: :Entourage).delete_all
    ChatMessage
      .joins("left join entourages on entourages.id = messageable_id")
      .where("entourages is null")
      .delete_all

    user_ids = []
    user_ids += User.where("created_at >= ?", time_limit).pluck(:id)
    user_ids += Entourage.uniq.pluck(:user_id)
    user_ids += JoinRequest.uniq.pluck(:user_id)
    user_ids += EntourageInvitation.uniq.pluck(:inviter_id)
    user_ids += EntourageInvitation.uniq.pluck(:invitee_id)
    user_ids += ChatMessage.uniq.pluck(:user_id)

    User.where.not(community: :entourage).delete_all
    User.where.not(id: user_ids.uniq).delete_all

    default_attributes = {
      device_id: nil,
      device_type: nil,
      sms_code: BCrypt::Password.create('123456'),
      organization_id: nil,
      manager: false,
      default_latitude: nil,
      default_longitude: nil,
      admin: false,
      user_type: :public,
      avatar_key: nil,
      marketing_referer_id: 1,
      atd_friend: false,
      use_suggestions: false,
      about: nil,
      encrypted_password: nil,
      roles: []
    }

    team = User.find_by email: 'guillaume@entourage.social'
    standard_users = User.where("id != ?", team.id)
    first_names = standard_users.where("first_name <> ''").uniq.pluck(:first_name)
    last_names  = standard_users.where("last_name  <> ''").uniq.pluck(:last_name)
    total = User.count

    User.find_each.with_index(1) do |user, i|
      attributes = {}

      attributes[:phone] = user.id.to_s.rjust(12, '+33600000000')
      attributes[:token] = SecureRandom.hex(16)

      if user == team
        attributes[:admin] = true
      else
        attributes[:email] = "#{user.id}@example.org" if user.email.present?
        attributes[:first_name] = first_names.sample  if user.first_name.present?
        attributes[:last_name]  = last_names.sample   if user.last_name.present?
      end

      user.update_columns(default_attributes.merge(attributes))

      print '.'
      puts "#{i}/#{total}" if i % 100 == 0 || i == total
    end

    # Poi and Category
  end
end
