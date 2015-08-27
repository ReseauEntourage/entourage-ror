ActiveAdmin.register Encounter do

  permit_params :date, :street_person_name, :message, :latitude, :longitude, :voice_message_url
  active_admin_import

end
