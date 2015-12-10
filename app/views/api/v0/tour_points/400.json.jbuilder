json.error do
  json.status 400
  json.message 'Could not create tour point'
  json.reasons @tour_points.map{|tour_point| tour_point.errors.full_messages unless tour_point.errors.blank? }.compact
end
