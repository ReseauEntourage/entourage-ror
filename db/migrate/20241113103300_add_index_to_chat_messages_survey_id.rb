class AddIndexToChatMessagesSurveyId < ActiveRecord::Migration[6.1]
  def change
    add_index :chat_messages, :survey_id
  end
end
