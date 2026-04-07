# @see https://metabase-analytics.entourage.social/question/2135-el-scoring-engagements-score-total-par-filtre-date
class CreateUserScorings < ActiveRecord::Migration[6.1]
  def change
    create_table :user_scorings do |t|
      t.integer :user_id
      t.integer :entourage_area_id

      t.integer :connexions_score
      t.integer :reactions_score
      t.integer :surveys_score
      t.integer :pedago_score
      t.integer :joined_groups_score
      t.integer :private_messages_score
      t.integer :event_messages_score
      t.integer :comment_replies_score
      t.integer :bonnes_ondes_score
      t.integer :group_posts_score
      t.integer :event_participation_score
      t.integer :create_entraide_score
      t.integer :create_group_score
      t.integer :create_event_score
      t.integer :total_score

      t.string :segment

      t.index :user_id
      t.index :entourage_area_id
    end
  end
end
