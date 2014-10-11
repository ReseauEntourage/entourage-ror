ActiveAdmin.register Poi do

  permit_params :name, :description, :longitude, :latitude, :adress, :phone, :website, :email, :audience, :category, :category_id
  active_admin_import

end
