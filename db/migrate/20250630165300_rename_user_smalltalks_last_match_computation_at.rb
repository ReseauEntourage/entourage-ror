class RenameUserSmalltalksLastMatchComputationAt < ActiveRecord::Migration[6.1]
  def change
    rename_column :user_smalltalks, :last_match_computation_at, :last_almost_match_computation_at
  end
end

