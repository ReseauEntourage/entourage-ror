class EncryptMessageFromEncounters < ActiveRecord::Migration
  def change
    remove_column :encounters, :message, :string
    add_column :encounters, :encrypted_message, :string
  end
end
