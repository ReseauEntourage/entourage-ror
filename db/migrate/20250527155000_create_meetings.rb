class CreateMeetings < ActiveRecord::Migration[6.1]
  def change
    create_table :meetings do |t|
      t.string :title
      t.datetime :start_time
      t.datetime :end_time
      t.text :participant_emails, array: true, default: []
      t.string :meet_link

      t.timestamps
    end
  end
end
