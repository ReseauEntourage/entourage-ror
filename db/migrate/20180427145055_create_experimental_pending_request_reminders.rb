class CreateExperimentalPendingRequestReminders < ActiveRecord::Migration[4.2]
  def change
    create_table :experimental_pending_request_reminders do |t|
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
