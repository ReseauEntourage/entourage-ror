module EntouragesHelper
  def link_to_entourage_with_infos entourage
    content_tag(:div, class: "o-entourage-title") do
      link_to("#{entourage.title.try(:capitalize)} (##{entourage.id})", admin_entourage_path(entourage))+
      content_tag(:br)+
      entourage_state_label(entourage)+
      entourage_type_label(entourage)
    end
  end

  def entourage_state_label entourage
    state_to_class = {
      "open"        => "label-success",
      "closed"      => "label-danger",
      "blacklisted" => "label-default"
    }
    content_tag :span, entourage.status, class: "label #{state_to_class[entourage.status]}"
  end

  def entourage_type_label entourage
    type_to_class = {
      "ask_for_help" => "label-warning",
      "contribution" => "label-info"
    }
    content_tag :span, entourage.entourage_type, class: "label #{type_to_class[entourage.entourage_type]}"
  end

  def entourage_invitation_type_label entourage_invitation
    type_to_class = {
      "pending"  => "label-warning",
      "accepted" => "label-success",
      "rejected" => "label-danger"
    }
    content_tag :span, entourage_invitation.status, class: "label #{type_to_class[entourage_invitation.status]}"
  end

  def entourage_description_excerpt description
    return unless description.present?
    content = description.length > 140 ? "#{description[0...140]}..." : description

    content_tag(:span, content)
  end
end
