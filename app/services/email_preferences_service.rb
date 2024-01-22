module EmailPreferencesService
  def self.update_url user:, accepts_emails:, category:
    Rails.application.routes.url_helpers.email_preferences_api_v1_user_url(
      user, accepts_emails: accepts_emails, category: category,
      signature: SignatureService.sign(user.id),
      host: API_HOST,
      protocol: (Rails.env.development? ? :http : :https)
    )
  end

  def self.reload_categories
    @categories = Hash[EmailCategory.pluck(:name, :id)].symbolize_keys
  end

  def self.categories_ids
    (@categories || reload_categories)
  end

  def self.categories
    categories_ids.keys
  end

  def self.category_id name
    categories_ids[name&.to_sym]
  end

  def self.user_preferences user
    EmailCategory
      .joins(%(
        left join email_preferences
          on email_preferences.email_category_id = email_categories.id and
             email_preferences.user_id = #{Integer(user.id)}
      ))
      .select(:name, :description, "coalesce(subscribed, true) as subscribed")
  end

  def self.update_subscription user:, subscribed:, category:
    category = category.to_sym

    if category == :all
      EmailPreference.transaction do
        categories.each do |category|
            update_subscription(
              user: user, subscribed: subscribed, category: category)
        end
      end
    else
      ensure_category_exists!(category)
      EmailPreference
        .find_or_initialize_by(user: user, email_category_id: category_id(category))
        .update(subscribed: subscribed)
    end
  end

  def self.update user:, preferences:
    # @fixme Ugly quick fix
    true_values = Set.new([true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"])

    preferences.symbolize_keys
    current_value = Hash[user_preferences(user).map { |c| [c.name.to_sym, c.subscribed] }]
    updates = {}
    EmailPreferencesService.categories.each do |category|
      requested_value = preferences[category].in?(true_values)
      if requested_value != current_value[category]
        updates[category] = requested_value
      end
    end

    success = true

    EmailPreference.transaction do
      updates.each do |category, requested_value|
        success &&= update_subscription(
          user: user, subscribed: requested_value, category: category)
      end
    end if updates.any?

    success
  end

  def self.ensure_category_exists! category
    category = category&.to_sym

    return true if category == :all || category_id(category) != nil

    exception = RuntimeError.new("EmailCategory #{category.inspect} not found")
    if Rails.env.development?
      raise exception
    else
      Raven.capture_exception(exception)
    end

    false
  end

  def self.accepts_emails? user:, category:
    unsubscribes = EmailPreference.where(user: user, subscribed: false)
    ensure_category_exists!(category)
    if category != :all
      unsubscribes = unsubscribes.where(email_category_id: category_id(category))
    end
    unsubscribes.exists? == false
  end
end
