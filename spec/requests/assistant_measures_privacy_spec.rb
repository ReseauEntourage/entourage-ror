require 'rails_helper'

# EN-9878, task 6.3: the anonymous measures (fears at the registration, feeling after a meeting) are
# kept by the assistant, per event or type of meeting, never per person. Local designates the subject
# (see the sheet of an outing) and receives no individual answer: it must neither accept nor keep one.
describe 'Anonymous measures: Local keeps no individual answer', type: :request do
  let(:marker) { 'RESSENTI-INDIVIDUEL-7731' }
  let(:user) { create :public_user, token: 'user-secret-token' }
  let(:organizer) { create :public_user }
  let!(:outing) { create :outing, :outing_class, user: organizer }
  let(:headers) { { 'X-API-KEY' => 'assistant-secret-key', 'Authorization' => "Bearer #{user.token}" } }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
  end

  # Everything that Rails and Lograge write while the block runs.
  def logged
    io = StringIO.new
    lograge = Lograge.logger
    Lograge.logger = ActiveSupport::Logger.new(io)
    Rails.logger.broadcast_to(extra = ActiveSupport::Logger.new(io))
    yield
    io.string
  ensure
    Lograge.logger = lograge
    Rails.logger.stop_broadcasting_to(extra)
  end

  # The number of rows, in every table, whose text holds the marker.
  def rows_with_marker
    connection = ActiveRecord::Base.connection
    connection.tables.sum do |table|
      connection.select_value(%(SELECT count(*) FROM "#{table}" t WHERE t::text LIKE #{connection.quote("%#{marker}%")})).to_i
    end
  end

  # A journey as the assistant could drive it, with the individual answers it must NOT send
  # to Local slipped into every request.
  def simulate_journey
    answers = { fear: marker, fears: [marker], feeling: marker, felt_at_place: marker, comment: marker, free_text: marker }

    get "/api/v1/assistant/profile", params: answers, headers: headers
    get "/api/v1/assistant/outings/#{outing.uuid_v2}", params: answers, headers: headers
    get "/api/v1/assistant/outings/#{outing.uuid_v2}/participation", params: answers, headers: headers
    post "/api/v1/assistant/outings/#{outing.uuid_v2}/join", params: answers.to_json,
         headers: headers.merge('Idempotency-Key' => SecureRandom.uuid, 'Content-Type' => 'application/json')
    get "/api/v1/assistant/activity", params: answers, headers: headers
    post "/api/v1/assistant/outings/#{outing.uuid_v2}/leave", params: answers.to_json,
         headers: headers.merge('Idempotency-Key' => SecureRandom.uuid, 'Content-Type' => 'application/json')
  end

  it 'has no route that receives or reads an individual answer, a measure or a feeling' do
    routes = Rails.application.routes.routes.map { |route| "#{route.verb} #{route.path.spec}" }.grep(%r{/api/v1/assistant})

    expect(routes).not_to be_empty
    expect(routes.join("\n")).not_to match(/measure|feeling|fear|answer|response|survey|ressenti/i)
  end

  it 'serves the whole journey without error' do
    simulate_journey

    expect(response.status).to eq(200) # the last step: the registration is cancelled
    expect(JoinRequest.find_by(joinable: outing, user: user).status).to eq('cancelled')
  end

  it 'would find a marker if one was kept (the scan of the tables is not blind)' do
    create :chat_message, content: marker

    expect(rows_with_marker).to be >= 1
  end

  it 'keeps the individual answers in no table' do
    simulate_journey

    expect(rows_with_marker).to eq(0)
  end

  it 'keeps the individual answers in no log' do
    expect(logged { simulate_journey }).not_to include(marker)
  end

  it 'does not even keep them in the idempotency table, which holds identifiers and statuses only' do
    simulate_journey

    expect(AssistantAction.pluck(:result, :request_digest, :action_type).to_json).not_to include(marker)
  end

  it 'only designates the subject of the measures: the stable id of the event and its type of meeting' do
    get "/api/v1/assistant/outings/#{outing.uuid_v2}", headers: headers

    expect(JSON.parse(response.body).slice('subjectId', 'meetingType')).to eq('subjectId' => outing.uuid_v2, 'meetingType' => 'event')
  end

  it 'only ever sends the assistant an account event, never an answer' do
    allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return('https://assistant.example.org/events')
    allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return('local-service-key')
    stub = stub_request(:post, 'https://assistant.example.org/events').to_return(status: 200)

    simulate_journey
    AssistantAccountEventJob.new.perform(user.uuid, 'account.deleted', Time.current.iso8601)

    expect(stub).to have_been_requested.once
    expect(a_request(:any, /assistant\.example\.org/).with { |request| request.body.include?(marker) }).not_to have_been_made
  end
end
