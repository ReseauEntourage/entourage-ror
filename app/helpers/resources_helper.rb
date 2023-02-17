module ResourcesHelper
  def categories_options_for_select
    Resource::CATEGORIES.map do |category|
      [category_label(category), category]
    end
  end

  def category_label category
    I18n.t("activerecord.attributes.resource.categories.#{category}")
  end

  def views_for resource
    resource.users.where(admin: false).count
  end
end
