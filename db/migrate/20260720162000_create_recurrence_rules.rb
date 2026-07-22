class CreateRecurrenceRules < ActiveRecord::Migration[7.1]
  def change
    create_table :recurrence_rules do |t|
      t.string :frequency, null: false
      t.date :ends_on, null: false
      t.boolean :active, null: false, default: true
      t.integer :created_by_id, null: false

      t.timestamps
    end

    add_index :recurrence_rules, :active
  end
end
