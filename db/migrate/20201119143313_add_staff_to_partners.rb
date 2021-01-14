class AddStaffToPartners < ActiveRecord::Migration[4.2]
  def change
    add_column :partners, :staff, :boolean, null: false, default: false
    reversible do |dir|
      dir.up do
        Partner.reset_column_information
        Partner.where("name like 'Entourage%'").update_all(staff: true)
        User.joins(:partner).merge(Partner.where(staff: true)).update_all(targeting_profile: :team)
      end
    end
  end
end
