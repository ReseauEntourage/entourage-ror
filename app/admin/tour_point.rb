ActiveAdmin.register TourPoint do

  permit_params :latitude, :longitude, :tour_id, :passing_time

end
