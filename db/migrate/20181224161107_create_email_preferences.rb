class CreateEmailPreferences < ActiveRecord::Migration[4.2]
  def up
    create_table :email_categories do |t|
      t.string :name, limit: 30, null: false
      t.string :description, limit: 100, null: false
    end
    add_index :email_categories, :name, unique: true

    create_table :email_preferences do |t|
      t.integer :user_id, null: false
      t.integer :email_category_id, null: false
      t.boolean :subscribed, null: false
      t.datetime :subscription_changed_at, null: false
    end
    add_index :email_preferences, [:user_id, :email_category_id], unique: true

    EmailCategory.create(
      name: :default,
      description: "messages automatiques liées à vos actions dans l'app")
    EmailCategory.create(
      name: :newsletter,
      description: 'newsletter mensuelle')
    EmailCategory.create(
      name: :unread_reminder,
      description: 'notification de nouveau message')

    # disable MailChimp callback
    EmailPreferencesService.define_singleton_method(:enable_mailchimp_callback?) { false }

    User.where(accepts_emails: false).find_each do |user|
      EmailPreferencesService.update_subscription(
        user: user, subscribed: false, category: :all)
    end

    rename_column :users, :accepts_emails, :accepts_emails_deprecated
  end

  def down
    drop_table :email_preferences
    drop_table :email_categories
    rename_column :users, :accepts_emails_deprecated, :accepts_emails
  end
end
