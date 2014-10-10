unless @error
  json.set! :user do
    json.id @user.id.to_s
    json.email @user.email
    end
else
  json.set! :error do
    json.message 'User not found'
  end
end
