ActiveAdmin.register Encounter do

  permit_params :date, :user_id, :user, :street_person_name, :message, :latitude, :longitude, :voice_message_url
  active_admin_import

end
