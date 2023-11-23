module ResourcesHelper
  def categories_options_for_select
    Resource::CATEGORIES.map do |category|
      [category_label(category), category]
    end
  end

  def category_label category
    I18n.t("activerecord.attributes.resource.categories.#{category}")
  end

  def tags_options_for_select
    Resource::TAGS.map do |tag|
      [tag_label(tag), tag]
    end
  end

  def tag_label tag
    return unless tag.present?

    I18n.t("activerecord.attributes.resource.tags.#{tag}")
  end

  def views_for resource
    resource.users.where(admin: false).count
  end
end
