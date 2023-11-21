class AddZoneAndStatusToNewsletterSubscriptions < ActiveRecord::Migration[6.1]
  def change
    add_column :newsletter_subscriptions, :zone, :string
    add_column :newsletter_subscriptions, :status, :string
  end
end
