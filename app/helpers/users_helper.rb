module UsersHelper
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

  def user_avatar_image user, *args
    url = UserServices::Avatar.new(user: user).thumbnail_url
    return unless url

    image_tag(url, *args)
  end
end
