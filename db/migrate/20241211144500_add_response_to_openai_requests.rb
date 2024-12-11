class AddResponseToOpenaiRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :openai_requests, :response, :string
  end
end
