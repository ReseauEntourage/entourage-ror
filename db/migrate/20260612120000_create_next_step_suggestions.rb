class CreateNextStepSuggestions < ActiveRecord::Migration[7.1]
  def change
    create_table :next_step_suggestions do |t|
      t.string :suggestion_type, null: false
      t.string :target_profile, default: 'all'
      t.integer :min_engagement_level, default: 0
      t.integer :max_engagement_level, default: 4
      t.string :title_template, null: false
      t.string :reason_template
      t.string :cta_label, null: false
      t.string :cta_action
      t.integer :priority, default: 0
      t.integer :valid_for_days, default: 7
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
