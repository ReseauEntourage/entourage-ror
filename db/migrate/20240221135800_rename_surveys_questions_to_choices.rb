class RenameSurveysQuestionsToChoices < ActiveRecord::Migration[6.1]
  def change
    rename_column :surveys, :questions, :choices
  end
end

