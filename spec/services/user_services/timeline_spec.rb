require 'rails_helper'

describe UserServices::Timeline do
  let(:user) { FactoryBot.create(:public_user) }

  subject { described_class.new(user).get }

  it 'includes entourages created by the user' do
    entourage = FactoryBot.create(:entourage, user: user, created_at: 2.days.ago)

    item = subject.find { |i| i[:kind] == :created }
    expect(item[:record]).to eq(entourage)
  end

  it 'excludes conversations' do
    FactoryBot.create(:conversation, user: user)

    expect(subject).to be_empty
  end

  it 'includes accepted join requests on entourages and neighborhoods' do
    entourage = FactoryBot.create(:entourage)
    neighborhood = FactoryBot.create(:neighborhood)
    FactoryBot.create(:join_request, joinable: entourage, user: user, status: 'accepted', created_at: 3.days.ago)
    FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: 'accepted', created_at: 1.day.ago)
    FactoryBot.create(:join_request, joinable: FactoryBot.create(:entourage), user: user, status: 'pending')

    kinds = subject.map { |i| i[:kind] }
    expect(kinds).to contain_exactly(:joined_entourage, :joined_neighborhood)
  end

  it 'sorts items most recent first' do
    FactoryBot.create(:entourage, user: user, created_at: 5.days.ago)
    FactoryBot.create(:entourage, user: user, created_at: 1.day.ago)

    dates = subject.map { |i| i[:date] }
    expect(dates).to eq(dates.sort.reverse)
  end

  it 'includes neighborhoods created by the user' do
    neighborhood = FactoryBot.create(:neighborhood, user: user)

    item = subject.find { |i| i[:kind] == :created_neighborhood }
    expect(item[:record]).to eq(neighborhood)
  end

  it 'exposes the entourage moderator when the entourage has been moderated' do
    moderator = FactoryBot.create(:admin_user)
    entourage = FactoryBot.create(:entourage, user: user)
    entourage.moderation.update!(moderator: moderator)

    item = subject.find { |i| i[:kind] == :created }
    expect(item[:moderator]).to eq(moderator)
  end

  it 'has a nil moderator when the entourage has not been moderated' do
    FactoryBot.create(:entourage, user: user)

    item = subject.find { |i| i[:kind] == :created }
    expect(item[:moderator]).to be_nil
  end
end
