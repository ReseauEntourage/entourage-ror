require 'rails_helper'

# Contract test between the AI assistant and Local (EN-9878).
#
# The assistant records every request that it sends to Local (test/contract/local-requests.json of
# entourage-assistant-api, copied in spec/fixtures/assistant_contract/local-requests.json). This spec
# replays each of them, with the headers it declares, against the real controllers of Local, on data that
# fits the case, and writes the real answers to spec/fixtures/assistant_contract/responses (see
# AssistantContractHelper): the assistant checks that its schemas accept them.
#
# A request that is refused wrongly is a gap of the contract: the expected status of the case says it.
# The refusals that the assistant handles and that it does not send are in contract_refusals_spec.rb.
describe 'Assistant contract: the requests of the assistant', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  REQUESTS = JSON.parse(File.read(AssistantContractHelper::CONTRACT_DIR.join('local-requests.json'))).freeze
  BASE = '/api/v1/assistant'.freeze
  # The ids that the assistant invents in its own test data: the real ones come from the answers of Local.
  PLACEHOLDER_OUTING = 'a1b2c3d4e5f6'.freeze
  PLACEHOLDER_GROUP = 'g1abc2def345'.freeze
  PLACEHOLDER_MEMBER = 'u-9'.freeze
  # The categories of help of the assistant's test data are numbers, those of Local are slugs.
  CATEGORIES = { '3' => 'services', '4' => 'equipment' }.freeze

  # Cases that need the user to be registered to the outing; every other case: not registered.
  REGISTERED = [
    'unregister-local-outing (execute)', 'post-local-outing-discussion (propose)', 'post-local-outing-discussion (execute)'
  ].freeze
  # The status expected for a request: 200 for a read, 201 for an action, but a cancellation.
  EXPECTED = { 'unregister-local-outing (execute)' => 200 }.freeze

  let(:now) { Time.zone.parse('2026-11-23 12:00:00 UTC') }
  let(:starts_at) { now + 3.days }
  let(:token) { 'user-secret-token' }

  around { |example| travel_to(now) { example.run } }

  let!(:user) do
    create :public_user, token: token, first_name: 'Camille', last_name: 'Dupont', goal: 'offer_help', travel_distance: 20,
                         interests: %w[sport jeux], availability: { '1' => ['09:00-12:00'] }, gender: 'female'
  end
  let!(:address) { create :address, user: user, city: 'Lyon', latitude: 45.764, longitude: 4.8357 }
  let(:organizer) { create :public_user, first_name: 'Léa', last_name: 'Bernard' }
  let!(:paul) { create :public_user, first_name: 'Paul', last_name: 'Martin' }
  let!(:outing) do
    create :outing, :outing_class, user: organizer, title: 'Café partagé', description: 'Un café, puis une balade',
                                   latitude: 45.764, longitude: 4.8357,
                                   metadata: { starts_at: starts_at, ends_at: starts_at + 2.hours, place_name: 'Café des Lilas',
                                               street_address: '12 rue des Lilas, 69001 Lyon, France', google_place_id: 'foo', place_limit: 12 }
  end
  let!(:women_outing) do
    create :outing, :outing_class, user: organizer, title: 'Marche entre femmes', latitude: 45.764, longitude: 4.8357,
                                   metadata: { starts_at: starts_at + 1.day, ends_at: starts_at + 1.day + 2.hours, place_name: 'Parc',
                                               street_address: '1 rue du Parc, 69006 Lyon, France', google_place_id: 'foo', reserved_female: true }
  end
  let!(:chat_outing) do
    create :outing, :outing_class, user: organizer, title: 'Papotage solidaire', online: true, latitude: 45.764, longitude: 4.8357,
                                   metadata: { starts_at: starts_at + 2.days, ends_at: starts_at + 2.days + 1.hour,
                                               street_address: 'Événement en ligne', google_place_id: '_online_' }
  end
  let!(:group) { create :neighborhood, name: 'Foot Lyon', user: organizer }
  let!(:animator) { create :public_user, first_name: 'Nadia', last_name: 'Roux', slack_id: 'U0NADIA' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return(AssistantContractHelper::API_KEY)
    allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')

    create :join_request, user: paul, joinable: outing, status: :accepted, role: :participant
    # The activity of the user: a group that it belongs to and a help of each kind that it published.
    create :join_request, user: user, joinable: create(:neighborhood, name: 'Voisins du quartier', user: organizer), status: :accepted
    create :solicitation, user: user, title: 'Aide pour mes courses', latitude: 45.764, longitude: 4.8357, section_list: ['services']
    create :contribution, user: user, title: 'Je prête mon vélo', latitude: 45.764, longitude: 4.8357, section_list: ['equipment']
    create :moderation_area, departement: '*', animator: animator
    create :solicitation, user: paul, title: 'Besoin de courses', latitude: 45.764, longitude: 4.8357, section_list: ['services']
    create :contribution, user: paul, title: 'Je prête une perceuse', latitude: 45.764, longitude: 4.8357, section_list: ['equipment']

    allow(Geocoder).to receive(:search).and_call_original
    allow(Geocoder).to receive(:search).with('Parc de la Tête d’Or, Lyon').and_return([
      double(latitude: 45.7772, longitude: 4.8553, address: 'Parc de la Tête d’Or, 69006 Lyon, France', place_id: 'ChIJteteor')
    ])
  end

  def aliases
    {
      user.uuid => '<user-uuid>', organizer.uuid => '<organizer-uuid>', paul.uuid => '<paul-uuid>', animator.uuid => '<animator-uuid>',
      outing.uuid_v2 => '<outing-id>', women_outing.uuid_v2 => '<women-outing-id>', chat_outing.uuid_v2 => '<chat-outing-id>',
      group.uuid_v2 => '<group-id>'
    }
  end

  # The headers are the ones that the assistant declares: a header that Local does not know is a gap.
  def headers_for(request, key)
    request['headerNames'].each_with_object({}) do |name, headers|
      headers[name] =
        case name
        when 'Accept', 'Content-Type' then 'application/json'
        when 'Authorization' then "Bearer #{token}"
        when 'X-API-KEY' then AssistantContractHelper::API_KEY
        when 'Idempotency-Key' then key
        else raise "the assistant sends a header that the contract does not know: #{name}"
        end
    end
  end

  def real_path path
    path.sub(PLACEHOLDER_OUTING, outing.uuid_v2).sub(PLACEHOLDER_GROUP, group.uuid_v2).sub(PLACEHOLDER_MEMBER, paul.uuid)
  end

  def real_value value
    CATEGORIES.fetch(value, value)
  end

  def snapshot_name index, request
    slug = request['name'].downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
    format('%<index>02d-%<slug>s', index: index, slug: slug)
  end

  it 'replays the requests of the assistant' do
    expect(REQUESTS.size).to be >= 37
    expect(REQUESTS.map { |request| request['path'].split('/')[1] }.uniq).to include('profile', 'outings', 'help_requests', 'alerts')
  end

  REQUESTS.each_with_index do |request, index|
    it "#{index}: #{request['name']} (#{request['method']} #{request['path']})" do
      create :join_request, user: user, joinable: outing, status: :accepted, role: :participant if REGISTERED.include?(request['name'])
      key = format('c0ffee00-0000-4000-8000-%012d', index)
      query = request['query'].to_h.transform_values { |value| real_value(value) }
      body = request['body']&.transform_values { |value| value == '3' || value == '4' ? real_value(value) : value }
      body = body.merge('category' => real_value(body['category'])) if body&.key?('category')

      path = "#{BASE}#{real_path(request['path'])}"
      path = "#{path}?#{query.to_query}" if query.present?
      args = { headers: headers_for(request, key) }
      args[:params] = body.to_json if body
      public_send(request['method'].downcase, path, **args)

      expected = EXPECTED.fetch(request['name'], request['method'] == 'GET' ? 200 : 201)
      expect(response.status).to eq(expected), "#{request['method']} #{request['path']} answered #{response.status}: #{response.body[0, 300]}"
      check_snapshot snapshot_name(index, request), aliases: aliases.merge(key => '<key>')
    end
  end

  it 'answers a read of the dedicated contact without contact, without error' do
    ModerationArea.delete_all
    User.where(admin: true).update_all(admin: false)

    send_as_assistant(:get, "#{BASE}/referent", token: token)

    expect(response.status).to eq(200)
    check_snapshot 'extra-referent-absent', aliases: aliases
  end

  it 'answers a read of the sheet of a full outing with its place limit, and of a women only outing' do
    send_as_assistant(:get, "#{BASE}/outings/#{women_outing.uuid_v2}", token: token)
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)['reservedFemale']).to eq(true)
    check_snapshot 'extra-outing-women-only', aliases: aliases

    send_as_assistant(:get, "#{BASE}/outings/#{outing.uuid_v2}/participation", token: token)
    check_snapshot 'extra-participation-not-registered', aliases: aliases
  end
end
