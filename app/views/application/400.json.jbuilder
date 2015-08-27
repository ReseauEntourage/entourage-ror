json.error do
  json.status 400
  json.message 'Could not create entity'
  json.reasons @entity.errors.full_messages if !@entity.nil?
end
