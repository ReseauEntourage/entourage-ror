json.error do
  json.status 400
  json.message 'Could not create encouter'
  json.reasons @encounter.errors.full_messages
end