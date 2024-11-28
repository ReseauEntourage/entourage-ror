class RenameOpenaiAssistantsToOpenaiRequests < ActiveRecord::Migration[6.1]
  def change
    rename_table :openai_assistants, :openai_requests
  end
end
