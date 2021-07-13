class UpdateEntouragesDisplayCategories < ActiveRecord::Migration[5.1]
  def up
    # keep the migration safe
    add_column :entourages, :display_category_copy, :string

    execute <<-SQL
      update entourages set display_category_copy = display_category;
      update entourages set display_category = 'other' where group_type = 'action' and display_category in ('event', 'info', 'skill');
    SQL
  end

  def down
    execute <<-SQL
      update entourages set display_category = display_category_copy;
    SQL

    remove_column :entourages, :display_category_copy
  end
end

