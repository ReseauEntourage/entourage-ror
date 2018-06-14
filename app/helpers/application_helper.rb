module ApplicationHelper
  
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
  
end
