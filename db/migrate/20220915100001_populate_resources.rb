require "#{Rails.root}/lib/tasks/populate.rb"

class PopulateResources < ActiveRecord::Migration[5.2]
  def up
    return if EnvironmentHelper.test?

    Populate.set_resources
  end

  def down
    Populate.delete_resources
  end
end

