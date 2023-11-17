class AddIndexEmailToNewsletterSubscriptions < ActiveRecord::Migration[6.1]
  def up
    add_index :newsletter_subscriptions, :email
  end

  def down
    remove_index :newsletter_subscriptions, :email
  end
end
