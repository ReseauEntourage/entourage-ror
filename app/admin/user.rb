ActiveAdmin.register User do

  permit_params :email, :first_name, :last_name, :phone, :sms_code, :manager, :organization_id
  active_admin_import

end
