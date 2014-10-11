class AddVoiceMessageUrlToEncounters < ActiveRecord::Migration
  def change
    add_column :encounters, :voice_message_url, :string
  end
end
