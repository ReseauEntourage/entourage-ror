class CreateSoliguideOption < ActiveRecord::Migration[5.2]
  def up
    unless EnvironmentHelper.test?
      Option.create(key: :soliguide, active: true, description: 'Allow to display Soliguide POI')
    end
  end

  def down
    unless EnvironmentHelper.test?
      Option.find_by_key(:soliguide).destroy
    end
  end
end

