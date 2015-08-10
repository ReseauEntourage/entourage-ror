json.user do
  json.id @user.id
  json.email @user.email
  json.first_name @user.first_name
  json.last_name @user.last_name
  json.token @user.token
  json.stats do
    json.tour_count @tour_count
    json.encounter_count @encounter_count
  end
end