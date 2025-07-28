module UsersHelper
  def users_for_select users
    users.map do |user|
      ["#{user.full_name} (#{user.email})", user.id]
    end
  end

  def user_state_label validation_status
    state_to_class = {
      "accepted"  => "label-success",
      "validated" => "label-success",
      "pending"   => "label-warning",
      "rejected"  => "label-danger",
      "blocked"   => "label-danger",
      "anonymized"=> "label-danger"
    }
    content_tag :span, validation_status, class: "label #{state_to_class[validation_status]}"
  end

  def user_avatar_image(user, *)
    url = UserServices::Avatar.new(user: user).thumbnail_url
    return unless url

    image_tag(url, *)
  end

  def user_profiles
    User::PROFILES.map do |profile|
      [t("community.user.profiles.#{profile}"), profile]
    end
  end

  def user_engagements
    [:engaged, :not_engaged].map do |engagement|
      [t("community.user.engagements.#{engagement}"), engagement]
    end
  end

  def user_statuses
    User::STATUSES.map do |status|
      [t("community.user.statuses.#{status}"), status]
    end
  end

  def user_roles
    User::ROLES.map do |role|
      [t("community.user.roles.#{role}"), role]
    end
  end
end
