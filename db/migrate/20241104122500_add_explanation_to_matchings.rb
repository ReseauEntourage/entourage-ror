class AddExplanationToMatchings < ActiveRecord::Migration[6.1]
  def change
    add_column :matchings, :explanation, :string, default: nil
  end
end
