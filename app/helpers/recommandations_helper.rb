module RecommandationsHelper
  def instances_options_for_select
    Recommandation::INSTANCES.sort.map do |instance|
      [instance_label(instance), instance]
    end
  end

  def instance_label instance
    I18n.t("activerecord.attributes.recommandation.instances.#{instance}")
  end

  def actions_options_for_select
    Recommandation::ACTIONS.sort.map do |action|
      [action_label(action), action]
    end
  end

  def action_label action
    I18n.t("activerecord.attributes.recommandation.actions.#{action}")
  end
end
