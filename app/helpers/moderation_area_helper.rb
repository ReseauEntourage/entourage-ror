module ModerationAreaHelper
  def region_text_for moderation_area
    "#{ModerationServices::Region.region_name(moderation_area.region)} (#{moderation_area.departement})"
  end

  def render_user_selection_field(form, attribute, area)
    content_tag(:div, class: 'form-group') do
      concat form.label "#{attribute}_id".to_sym

      if area.public_send(attribute).present?
        concat content_tag(:div) do
          link_to UserPresenter.full_name(area.public_send(attribute)), [:admin, area.public_send(attribute)]
        end

        unless area.public_send(attribute).moderator?
          concat content_tag(:i, "Attention, le modérateur choisi n'a pas les autorisations d'un modérateur. Merci d'en préciser un nouveau")
        end
      end

      concat form.select "#{attribute}_id".to_sym, options_for_select(moderators_for_select, area.public_send("#{attribute}_id")), { include_blank: true }, class: 'form-control'
    end
  end
end
