json.error do
  json.status 400
  json.message 'Could not create tour'
  json.reasons @tour.errors.full_messages
end
