require "#{Rails.root}/lib/tasks/populate.rb"

class PopulateRecommandations < ActiveRecord::Migration[5.2]
  def up
    return if EnvironmentHelper.test?

    Populate.set_recommandations
  end

  def down
    Populate.delete_recommandations
  end
end

