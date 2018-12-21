module DigestEmail
  module TextHelper
    extend ActionView::Helpers::TextHelper
  end

  def self.delivery(user_id, group_ids, content_id: nil)
    user = User.find(Integer(user_id))

    return if user.deleted

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

    url_parameters = {
      utm_source: :digest_email,
      utm_medium: :email,
      utm_content: content_id
    }.compact

    campaign_name = [:digest_email, content_id].compact.join('_')

    groups = groups.map { |g| group_payload(g, url_parameters: url_parameters) }

    return unless user.address &&
                  user.address.country == 'FR' &&
                  user.address.postal_code&.starts_with?('75')

    if user.address.postal_code =~ /\A750\d\d\z/
      arrondissement = user.address.postal_code.last(2).gsub(/^0/, '')
      area_name = "Paris #{arrondissement}e"
    else
      area_name = "Paris"
    end

    MemberMailer.mailjet_email(
      to: user,
      template_id: 592472,
      campaign_name: campaign_name,
      variables: {
        actions: groups,
        area_name: area_name
      }
    )
  end

  def self.group_payload group, url_parameters: {}
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

    url = "#{ENV['WEBSITE_URL']}/entourages/#{group.uuid_v2}"
    url_parameters.compact!
    url += "?" + url_parameters.compact.to_query if url_parameters.any?

    {
      title: group.title,
      description: description,
      icon: icon,
      location: location,
      url: url
    }
  end
end
