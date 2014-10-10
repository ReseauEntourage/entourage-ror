json.users @users do |user|
  json.id user.id.to_s
  json.email user.email
end