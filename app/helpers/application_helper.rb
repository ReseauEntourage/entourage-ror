module ApplicationHelper
  def smart_date datetime
    return l(datetime, format: "%H:%M") if datetime.today?
    return l(datetime, format: "%A") if datetime >= 7.days.ago.midnight

    l(datetime, format: "%-d %b")
  end

  def object_translation object, field, lang
    return object[field] if Translation.disable_on_read?
    return object[field] unless lang && object.translation

    object.translation.with_lang(lang)[field] || object[field]
  end

  def status_label instance
    type_to_class = {
      "active" => "info",
      "open" => "info",
      "full" => "info",
      "cancelled" => "warning",
      "deleted" => "warning",
      "closed" => "warning",
      "suspended" => "danger",
      "blacklisted" => "danger"
    }
    content_tag :span, instance.status, class: "custom-badge #{type_to_class[instance.status]}"
  end

  def boolean_label bool, options = {}
    # primary secondary success danger warning info light dark
    type_to_class = { true => "primary", false => "danger" }

    content_tag :span, options[:default] || bool || false, class: "badge bg-#{type_to_class[bool]}"
  end

  def active_class(link_path)
    current_page?(link_path) ? "active" : ""
  end

  def bootstrap_class_for(flash_type)
    { 'success' => "alert-success", 'error' => "alert-danger", 'alert' => "alert-warning", 'notice' => "alert-info" }[flash_type] || flash_type.to_s
  end

  def display_flash_messages(opts = {})
    flash.each do |msg_type, message|
      next if msg_type[0] == '_'
      concat(content_tag(:p, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
              concat content_tag(:button, 'x', class: "close", data: { dismiss: 'alert' })
              concat message
            end)
    end
    nil
  end

  def select_user_tag(form_object_name, selected_user, html_options = {})
    options = if selected_user
      [[user_option_label(selected_user), selected_user.id]]
    else
      []
    end

    select_tag(
      "#{form_object_name}[user_id]",
      options_for_select(options),
      {
        class: "form-control user-select",
        multiple: false,
        required: true,
        data: { placeholder: "utilisateur (prénom ou téléphone)" }
      }.merge(html_options)
    )
  end

  def user_option_label(user)
    "#{user.first_name} #{user.last_name} (#{user.phone})"
  end
end
