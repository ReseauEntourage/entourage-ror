class AddSummaryToSurveys < ActiveRecord::Migration[6.1]
  def change
    add_column :surveys, :summary, :jsonb, default: []
  end
end
