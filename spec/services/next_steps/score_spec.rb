require 'rails_helper'

RSpec.describe NextSteps::Score do
  let(:user) { create(:public_user, travel_distance: 40) }

  before do
    user.address.update_columns(latitude: 48.8566, longitude: 2.3522) if user.address
    allow(user).to receive(:latitude).and_return(48.8566)
    allow(user).to receive(:longitude).and_return(2.3522)
  end

  def candidate latitude: nil, longitude: nil, interest_list: nil, popularity: nil
    NextSteps::Candidate.new(kind: 'outing', target_ids: [], latitude: latitude, longitude: longitude, interest_list: interest_list, popularity: popularity)
  end

  it 'puts the closest first when interests and popularity are equal' do
    user.interest_list = ['sport']
    far = candidate(latitude: 49.0366, longitude: 2.3522, interest_list: ['sport'], popularity: 5) # ~20 km
    near = candidate(latitude: 48.8746, longitude: 2.3522, interest_list: ['sport'], popularity: 5) # ~2 km

    expect(described_class.new(user).rank([far, near])).to eq([near, far])
  end

  it 'weights distance 0.50, interests 0.40 and popularity 0.10' do
    user.interest_list = ['sport', 'cuisine']
    scored = described_class.new(user).rank([candidate(latitude: 48.8566, longitude: 2.3522, interest_list: ['sport'], popularity: 3)]).first

    # distance 1, interests 0.5, popularity 1 (the only candidate is the most popular)
    expect(scored.score).to be_within(0.001).of(0.50 * 1 + 0.40 * 0.5 + 0.10 * 1)
  end

  it 'drops the interests when the user declared none, and spreads their weight' do
    user.interest_list = []
    scored = described_class.new(user).rank([candidate(latitude: 48.8566, longitude: 2.3522, interest_list: ['sport'], popularity: 3)]).first

    expect(scored.score_components.keys).to contain_exactly(:distance, :popularity)
    expect(scored.score).to be_within(0.001).of((0.50 * 1 + 0.10 * 1) / 0.60)
  end

  it 'drops the distance of a candidate without place' do
    user.interest_list = ['sport']
    scored = described_class.new(user).rank([candidate(interest_list: ['sport'], popularity: nil)]).first

    expect(scored.score_components.keys).to eq([:interests])
    expect(scored.score).to eq(1.0)
  end

  it 'measures popularity on a logarithmic scale among the candidates' do
    small = candidate(popularity: 3)
    big = candidate(popularity: 99)

    described_class.new(user).rank([small, big])

    expect(small.score_components[:popularity]).to be_within(0.001).of(Math.log(4) / Math.log(100))
  end
end
