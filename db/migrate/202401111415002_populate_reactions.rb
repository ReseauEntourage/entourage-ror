require "#{Rails.root}/lib/tasks/populate.rb"

class PopulateReactions < ActiveRecord::Migration[6.1]
  def up
    return if EnvironmentHelper.test?

    Populate.set_reactions
  end

  def down
    Populate.delete_reactions
  end
end

