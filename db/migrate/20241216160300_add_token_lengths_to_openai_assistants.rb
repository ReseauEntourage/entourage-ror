class AddTokenLengthsToOpenaiAssistants < ActiveRecord::Migration[6.1]
  def change
    add_column :openai_assistants, :max_prompt_tokens, :integer, default: 1024*1024
    add_column :openai_assistants, :max_completion_tokens, :integer, default: 1024
  end
end
