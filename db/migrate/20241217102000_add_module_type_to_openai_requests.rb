class AddModuleTypeToOpenaiRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :openai_requests, :module_type, :string, default: :matching
  end
end
