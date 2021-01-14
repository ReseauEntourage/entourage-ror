class AddVoiceMessageUrlToEncounters < ActiveRecord::Migration[4.2]
  def change
    add_column :encounters, :voice_message_url, :string
  end
end
