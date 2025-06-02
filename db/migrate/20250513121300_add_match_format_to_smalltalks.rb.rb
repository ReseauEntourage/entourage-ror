class AddMatchFormatToSmalltalks < ActiveRecord::Migration[6.1]
  def change
    add_column :smalltalks, :match_format, :integer, nullable: false, default: 0
  end
end
