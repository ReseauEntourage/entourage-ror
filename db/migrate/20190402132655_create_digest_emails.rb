class CreateDigestEmails < ActiveRecord::Migration[4.2]
  def up
    create_table :digest_emails do |t|
      t.datetime :deliver_at, null: false
      t.jsonb :data, null: false, default: {}
      t.string :status, null: false
      t.datetime :status_changed_at, null: false
    end

    digest_email_category = EmailCategory.create!(
      name: :digest_email,
      description: 'actions recommandées à proximité (toutes les deux semaines)'
    )

    EmailPreference.transaction do
      EmailPreference.joins(:category)
        .where(subscribed: false, email_categories: {name: :default})
        .pluck(:user_id)
        .each do |user_id|
        EmailPreference.create!(
          email_category_id: digest_email_category.id,
          user_id: user_id,
          subscribed: false
        )
      end
    end
  end

  def down
    digest_email_category = EmailCategory.find_by(name: :digest_email)
    if digest_email_category
      digest_email_category.delete
      EmailPreference.where(email_category_id: digest_email_category.id).delete_all
    end
    drop_table :digest_emails
  end
end
