class CreateRegistrationRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :registration_requests do |t|
      t.string      :status, default: 'pending', null: false
      t.string      :extra,                      null: false
      t.timestamps                               null: false
    end
  end
end
