# @see https://metabase-analytics.entourage.social/question/2135-el-scoring-engagements-score-total-par-filtre-date
class AddDateToUserScorings < ActiveRecord::Migration[6.1]
  def change
    add_column :user_scorings, :date, :date, nullable: true, default: nil
  end
end
