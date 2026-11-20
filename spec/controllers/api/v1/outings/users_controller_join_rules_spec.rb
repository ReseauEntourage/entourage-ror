require 'rails_helper'

# Spike EN-9878 (task 1.1): documents what the app does today when a member joins an outing
# that is full or reserved to women. These specs describe the CURRENT behaviour, they do not
# endorse it: if one of them fails after a product decision, update it with the new rule.
describe Api::V1::Outings::UsersController, type: :controller do
  let(:organizer) { create(:public_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'POST create on an outing with a place limit' do
    let(:outing) { create(:outing, user: organizer, metadata: { place_limit: 1 }) }
    let(:first_participant) { create(:public_user) }
    let(:second_participant) { create(:public_user) }

    before do
      create(:join_request, user: organizer, joinable: outing, status: :accepted, role: :organizer)
      create(:join_request, user: first_participant, joinable: outing, status: :accepted, role: :participant)
      post :create, params: { outing_id: outing.to_param, token: second_participant.token }
    end

    # The limit is only displayed (place_limit): nothing refuses a member once it is reached.
    it { expect(response.status).to eq(201) }
    it { expect(outing.join_requests.accepted.count).to eq(3) }
  end

  describe 'POST create on an outing reserved to women' do
    let(:outing) { create(:outing, user: organizer, metadata: { reserved_female: true }) }
    let(:member) { create(:public_user) }

    before do
      create(:join_request, user: organizer, joinable: outing, status: :accepted, role: :organizer)
      member.update!(gender: gender) if gender
      post :create, params: { outing_id: outing.to_param, token: member.token }
    end

    # reserved_female only filters the lists (Outing.reserved_female, NextSteps): joining by id is
    # never refused, whatever the gender of the member.
    context 'when the member is a man' do
      let(:gender) { 'male' }

      it { expect(response.status).to eq(201) }
      it { expect(outing.join_requests.accepted.where(user: member)).to exist }
    end

    context 'when the member did not give a gender' do
      let(:gender) { nil }

      it { expect(response.status).to eq(201) }
      it { expect(outing.join_requests.accepted.where(user: member)).to exist }
    end

    context 'when the member is a woman' do
      let(:gender) { 'female' }

      it { expect(response.status).to eq(201) }
    end
  end
end
