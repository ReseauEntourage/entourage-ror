class ComputeNumberOfPeopleToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    return if EnvironmentHelper.test?

    Neighborhood.all.each do |neighborhood|
      neighborhood.members_has_changed!
      neighborhood.save
    end
  end

  def down
  end
end
