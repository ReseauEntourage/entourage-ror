class AddResponseToOpenaiRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :openai_requests, :response, :string
    add_column :openai_requests, :error, :string
  end
end
