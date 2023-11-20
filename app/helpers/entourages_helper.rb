module EntouragesHelper
  NO_CATEGORY = '(pas de catégorie)'.freeze

  def entourage_state_label entourage
    state_to_class = {
      "open"        => "label-success",
      "closed"      => "label-danger",
      "suspended"   => "label-warning",
      "blacklisted" => "label-default",
      "full"        => "label-warning",
      "cancelled"   => "label-warning",
    }
    content_tag :span, t("activerecord.attributes.entourage.statuses.#{entourage.status}"), class: "label #{state_to_class[entourage.status]}"
  end

  def entourage_type_label entourage
    type_to_class = {
      "ask_for_help" => "label-warning",
      "contribution" => "label-info"
    }
    content_tag :span, entourage.entourage_type, class: "label #{type_to_class[entourage.entourage_type]}"
  end

  def entourage_full_category entourage
    case entourage.group_type
    when 'outing'
      'contribution_event'
    when 'group'
      'contribution_social'
    else
      "#{entourage.entourage_type}_#{entourage.display_category || :other}"
    end
  end

  def entourage_category_image_path entourage
    "entourage/display_category/#{entourage_full_category entourage}.png"
  end

  def entourage_category_image entourage, options={}
    path = entourage_category_image_path(entourage)
    options[:title] ||= [entourage_type_phrase(entourage),
                         ' › ',
                         entourage_category_phrase(entourage)].join
    return unless path

    image_tag path, options
  end

  def entourage_type_name entourage
    if entourage.group_type == 'action'
      {
        'contribution' => "Contribution",
        'ask_for_help' => "Demande"
      }[entourage.entourage_type]
    else
      {
        'outing' => "Évènement",
        'group' => "Groupe",
      }[entourage.group_type]
    end
  end

  def entourage_type_names
    Entourage::ENTOURAGE_TYPES.map do |type|
      [t("activerecord.attributes.entourage.entourage_types.#{type}"), type]
    end
  end

  def entourage_type_statuses
    (Entourage::ENTOURAGE_STATUS|Entourage::OUTING_STATUS).map do |status|
      [I18n.t("activerecord.attributes.entourage.statuses.#{status}"), status]
    end
  end

  def entourage_type_categories
    Entourage::DISPLAY_CATEGORIES.map do |category|
      [t("activerecord.attributes.entourage.categories.#{category}"), category]
    end
  end

  def entourage_type_phrase entourage
    {
      'contribution' => "Je me propose de",
      'ask_for_help' => "Je cherche"
    }[entourage.entourage_type]
  end

  def entourage_category_phrase entourage
    {
      'ask_for_help_event'    => "Des bénévoles pour un évènement",
      'ask_for_help_info'     => "Poser une question au réseau",
      'ask_for_help_mat_help' => "Un don matériel",
      'ask_for_help_other'    => "Autre chose !",
      'ask_for_help_resource' => "Une ressource mise à disposition",
      'ask_for_help_skill'    => "Une compétence",
      'ask_for_help_social'   => "Des voisins pour entourer une personne",
      'contribution_event'    => "Inviter à un évènement solidaire",
      'contribution_info'     => "Diffuser une information",
      'contribution_mat_help' => "Faire un don matériel",
      'contribution_other'    => "Aider à ma façon",
      'contribution_resource' => "Mettre à disposition une ressource",
      'contribution_skill'    => "Donner une compétence",
      'contribution_social'   => "Passer du temps avec une personne"
    }[entourage_full_category entourage]
  end

  def entourage_invitation_type_label entourage_invitation
    type_to_class = {
      "pending"  => "label-warning",
      "accepted" => "label-success",
      "rejected" => "label-danger",
      "cancelled" => "label-info"
    }
    content_tag :span, entourage_invitation.status, class: "label #{type_to_class[entourage_invitation.status]}"
  end

  def entourage_description_excerpt description
    return unless description.present?
    content = description.length > 50 ? "#{description[0...50]}..." : description

    content_tag(:span, content)
  end

  def distance_in_words(meters)
    distance = meters.round
    case distance
    when 0..99 then "#{distance} m"
    when 100..299 then "#{(distance / 10.0).ceil * 10} m"
    when 300..999 then "#{(distance / 50.0).ceil * 50} m"
    when 1000..5000 then ("%1.1f km" % ((distance / 100.0).ceil / 10.0)).tr('.', ',')
    else "#{(distance / 1000.0).ceil} km"
    end
  end
end
