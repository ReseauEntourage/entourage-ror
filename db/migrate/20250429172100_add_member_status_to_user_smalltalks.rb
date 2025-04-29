class AddMemberStatusToUserSmalltalks < ActiveRecord::Migration[6.1]
  def change
    add_column :user_smalltalks, :member_status, :string, nullable: true
  end
end
