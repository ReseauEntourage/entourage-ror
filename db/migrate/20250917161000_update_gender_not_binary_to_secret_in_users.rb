class UpdateGenderNotBinaryToSecretInUsers < ActiveRecord::Migration[6.1]
  def up
    User
      .where("updated_at > '2025-01-01'")
      .where("options ->> 'gender' = ?", 'not_binary')
      .update_all("options = jsonb_set(options, '{gender}', '\"secret\"')")
    end
  end

  def down
    User
      .where("updated_at > '2025-01-01'")
      .where("options ->> 'gender' = ?", 'secret')
      .update_all("options = jsonb_set(options, '{gender}', '\"not_binary\"')")
    end
  end
end
