ActiveAdmin.register Organization do

  permit_params :name, :description, :phone, :address, :logo_url

end
