class CreateSurveys < ActiveRecord::Migration[6.1]
  def change
    create_table :surveys do |t|
      t.jsonb :questions, default: []
      t.boolean :multiple, default: false

      t.timestamps null: false
    end
  end
end

