json.array!(@registration_requests) do |registration_request|
  json.extract! registration_request, :id
  json.url registration_request_url(registration_request, format: :json)
end
