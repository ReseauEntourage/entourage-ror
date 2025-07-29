class AddCoordinatesToPartners < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.transaction do
      add_column :partners, :latitude, :float
      add_column :partners, :longitude, :float
      add_column :pois, :partner_id, :integer
      add_index :pois, :partner_id, unique: true
    end

    reversible do |dir|
      dir.up do
        Category.find_or_initialize_by(id: 8).update(name: 'Partenaires')
        Partner.reset_column_information
        Poi.reset_column_information
        Partner.find_each do |partner|
          partner.geocode
          partner.save
        end
      end

      dir.down do
        Poi.where(category_id: 8).delete_all
        Category.delete(8)
      end
    end unless Rails.env.test?
  end
end
