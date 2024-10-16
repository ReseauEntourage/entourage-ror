class RemoveEntouragesDisplayCategoryCopy < ActiveRecord::Migration[6.1]
  def up
    remove_column :entourages, :display_category_copy
  end

  def down
    add_column :entourages, :display_category_copy, :string

    execute <<-SQL
      update entourages set display_category_copy = display_category;
      update entourages set display_category = 'other' where group_type = 'action' and display_category in ('event', 'info', 'skill');
    SQL
  end
end
