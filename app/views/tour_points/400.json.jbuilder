json.error do
  json.status 400
  json.message 'Could not create tour point'
  json.reasons @tour_point.errors.full_messages
end
