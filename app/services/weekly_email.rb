module WeeklyEmail
  module TextHelper
    extend ActionView::Helpers::TextHelper
  end

  def self.delivery(user_id, group_ids)
    user = User.find(Integer(user_id))

    group_ids = group_ids
      .map(&:presence)
      .compact
      .map { |group_id| Integer(group_id) }
      .uniq

    groups =
      Entourage
      .where(community: user.community)
      .where(status: [:open, :closed])
      .where(group_type: [:action, :outing])
      .where(id: group_ids)
      .sort_by { |g| group_ids.index(g.id) }

    groups.select! do |g|
      g.country == 'FR' &&
      g.postal_code&.starts_with?('75')
    end

    auth_token = UserServices::UserAuthenticator.auth_token(user)

    groups = groups.map { |g| group_payload(g, auth_token: auth_token) }

    MemberMailer.mailjet_email(
      to: user,
      template_id: 592472,
      campaign_name: :weekly_email,
      variables: {
        actions: groups
      }
    )
  end

  def self.group_payload group, auth_token:
    participant_count = group.join_requests.accepted.count
    description = TextHelper.pluralize(participant_count, "participant")

    icon =
      case group.group_type
      when 'outing' then :event
      else group.display_category
      end

    location =
      case group.postal_code
      when /750\d\d/
        arrondissement = group.postal_code.last(2).to_i
        arrondissement =
          if arrondissement == 1
            "1er"
          else
            "#{arrondissement}ème"
          end
        "Paris #{arrondissement}"
      else
        group.postal_code
      end

    {
      title: group.title,
      description: description,
      icon: icon,
      location: location,
      url: "#{ENV['WEBSITE_URL']}/entourages/#{group.uuid_v2}?auth=#{auth_token}"
    }
  end
end
