ActiveAdmin.register Tour do

  permit_params :tour_type, :status, :vehicle_type, :user_id, :created_at, :closed_at, :length

end
