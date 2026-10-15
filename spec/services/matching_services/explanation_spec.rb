require 'rails_helper'

describe MatchingServices::Explanation do
  def candidate record, type:, distance_km: nil, category_match: false
    MatchingServices::Candidates::Candidate.new(record: record, type: type, distance_km: distance_km, category_match: category_match)
  end

  it 'gives the distance in meters under 1 km' do
    expect(described_class.for(candidate(build(:contribution), type: 'contribution', distance_km: 0.83, category_match: true))).to eq('À 800 m · même catégorie que votre action')
  end

  it 'gives the distance in kilometers and the date of an outing' do
    outing = build(:outing, :outing_class, default_metadata: { starts_at: Time.zone.parse('2026-10-22 19:00') })

    expect(described_class.for(candidate(outing, type: 'outing', distance_km: 2.46))).to eq('À 2,5 km · le 22 octobre')
  end

  it 'says when an outing is online' do
    outing = build(:outing, :outing_class, online: true, default_metadata: { starts_at: Time.zone.parse('2026-11-03 19:00') })

    expect(described_class.for(candidate(outing, type: 'outing'))).to eq('En ligne · le 3 novembre')
  end

  it 'says when the candidate is at the same place' do
    expect(described_class.for(candidate(build(:contribution), type: 'contribution', distance_km: 0.04))).to eq('Tout près')
  end

  it 'has a default explanation' do
    expect(described_class.for(candidate(build(:resource), type: 'resource'))).to eq('Proche du sujet de votre action')
  end
end
