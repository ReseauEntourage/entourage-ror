# @see https://metabase-analytics.entourage.social/question/2135-el-scoring-engagements-score-total-par-filtre-date
class DropUserScorings < ActiveRecord::Migration[6.1]
  def change
    drop_table :user_scorings
  end
end
