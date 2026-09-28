require 'rails_helper'

describe V1::OutingSerializer do
  let(:outing) { create :outing }
  let(:neighborhood) { create :neighborhood }

  let(:confirmed) { create :public_user }
  let(:accepted) { create :public_user }
  let(:pending) { create :public_user }
  let(:stranger) { create :public_user }

  before do
    create :join_request, joinable: outing, user: confirmed, status: :accepted, confirmed_at: Time.zone.now
    create :join_request, joinable: outing, user: accepted, status: :accepted
    create :join_request, joinable: outing, user: pending, status: :pending
    NeighborhoodsEntourage.create!(neighborhood: neighborhood, entourage: outing)
  end

  def serialize(outing, user)
    V1::OutingSerializer.new(outing, scope: { user: user }, root: false).as_json.slice(:member, :confirmed_member, :neighborhoods)
  end

  it 'serializes the same membership and neighborhoods with or without Preloaders::Outing.preload_for_serializer' do
    [confirmed, accepted, pending, stranger].each do |user|
      preloaded = Outing.where(id: outing.id).to_a
      Preloaders::Outing.preload_for_serializer(preloaded, user: user)

      expect(serialize(preloaded.first, user)).to eq(serialize(Outing.find(outing.id), user))
    end
  end

  it 'computes membership from the join request of the user' do
    results = [confirmed, accepted, pending, stranger].map do |user|
      preloaded = Outing.where(id: outing.id).to_a
      Preloaders::Outing.preload_for_serializer(preloaded, user: user)
      serialize(preloaded.first, user).values_at(:member, :confirmed_member)
    end

    expect(results).to eq([[true, true], [true, false], [false, false], [false, false]])
  end

  it 'lists the neighborhoods of the outing' do
    expect(serialize(Outing.find(outing.id), stranger)[:neighborhoods]).to eq([{ id: neighborhood.id, name: neighborhood.name }])
  end
end
