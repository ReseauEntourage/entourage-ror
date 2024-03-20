class PopulateCommentsCountOnChatMessages < ActiveRecord::Migration[6.1]
  def up
    sql = <<-SQL
      UPDATE chat_messages AS posts
      SET comments_count = subquery.descendants_count
      FROM (
          SELECT posts.id, COUNT(*) AS descendants_count
          FROM chat_messages AS posts
          JOIN chat_messages AS comments ON comments.ancestry::integer = posts.id
          WHERE comments.id IS NOT NULL
          GROUP BY posts.id
      ) AS subquery
      WHERE posts.id = subquery.id;
    SQL

    execute(sql)
  end

  def down
    sql = <<-SQL
      UPDATE chat_messages AS posts
      SET comments_count = 0
    SQL

    execute(sql)
  end
end
