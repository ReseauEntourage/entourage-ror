class AddSurveyIdToChatMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :chat_messages, :survey_id, :integer, default: nil
  end
end
