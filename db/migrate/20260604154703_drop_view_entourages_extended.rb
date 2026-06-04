class DropViewEntouragesExtended < ActiveRecord::Migration[7.1]
  def up
    execute 'DROP VIEW IF EXISTS entourages_extended;'
  end
end
