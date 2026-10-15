require 'rails_helper'

describe MatchingServices::Scorer do
  def candidate type: 'contribution', similarity: 0.45, distance_km: nil, freshness: nil, category_match: false
    MatchingServices::Candidates::Candidate.new(type: type, similarity: similarity, distance_km: distance_km, freshness: freshness, category_match: category_match)
  end

  describe '.score' do
    it 'weighs closeness of meaning first' do
      close = candidate(similarity: 0.7, distance_km: 9, freshness: 0)
      near = candidate(similarity: 0.3, distance_km: 0, freshness: 1, category_match: true)

      expect(described_class.score(close, 10)).to be > described_class.score(near, 10)
    end

    it 'gives 1 to a perfect candidate and 0 to the worst one' do
      expect(described_class.score(candidate(similarity: 0.9, distance_km: 0, freshness: 1, category_match: true), 10)).to eq(1)
      expect(described_class.score(candidate(similarity: 0.1, distance_km: 20, freshness: 0), 10)).to eq(0)
    end

    it 'is neutral on the signals that do not apply' do
      expect(described_class.score(candidate(similarity: 0.45), 10)).to be_within(0.001).of(0.6 * 0.5 + 0.2 * 0.5 + 0.1 * 0.5)
    end
  end

  describe '.shortlist' do
    let(:pois) { 6.times.map { |index| candidate(type: 'poi').tap { |poi| poi.score = 0.9 - index * 0.01 } } }
    let(:outings) { 2.times.map { |index| candidate(type: 'outing').tap { |outing| outing.score = 0.5 - index * 0.01 } } }
    let(:resources) { 3.times.map { |index| candidate(type: 'resource').tap { |resource| resource.score = 0.3 - index * 0.01 } } }

    subject { described_class.shortlist(pois + outings + resources) }

    it 'keeps at most 3 candidates of each type, best first' do
      expect(subject).to eq(pois.first(3) + outings + resources.first(3))
    end

    it 'keeps at most 10 candidates' do
      expect(described_class.shortlist(pois + outings + resources + resources.map(&:dup).each { |c| c.type = 'neighborhood' }).size).to eq(10)
    end
  end
end
