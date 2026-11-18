require 'rails_helper'

RSpec.describe NextSteps::EffectiveSegment do
  let(:user) { create(:public_user) }

  subject(:effective) { described_class.for(user) }

  it 'uses the computed segment' do
    create(:user_segment, user: user, engagement_segment: 'Curieux')

    expect([effective.segment, effective.sub_segment, effective.source]).to eq(['Curieux', nil, 'computed'])
  end

  it 'keeps a segment computed two days ago' do
    create(:user_segment, user: user, engagement_segment: 'Pilier', segment_computed_at: 2.days.ago)

    expect(effective.key).to eq('Pilier')
  end

  it 'treats a user without segment nor past engagement as À activer' do
    expect([effective.key, effective.source]).to eq(['Silencieux / À activer', 'assumed_new'])
  end

  it 'treats a user without segment but with a past engagement as Dormant' do
    create(:user_segment, user: user, engagement_segment: nil)
    create(:denorm_daily_engagements_with_type, user: user, date: 90.days.ago.to_date)

    expect([effective.key, effective.source]).to eq(['Silencieux / Dormant', 'assumed_returning'])
  end

  it 'treats a team member as Contributeur' do
    user.update_column(:targeting_profile, 'team')

    expect([effective.key, effective.source]).to eq(['Contributeur', 'team'])
  end
end

RSpec.describe NextSteps::Need do
  let(:user) { create(:public_user) }

  it 'is the latest open solicitation of less than 30 days' do
    create(:solicitation, user: user, created_at: 10.days.ago)
    latest = create(:solicitation, user: user, created_at: 5.days.ago, section_list: ['clothes'])

    need = described_class.for(user)

    expect([need.solicitation_id, need.sections]).to eq([latest.id, ['clothes']])
  end

  it 'ignores a solicitation older than 30 days' do
    create(:solicitation, user: user, created_at: 45.days.ago)

    expect(described_class.for(user)).to be_nil
  end

  it 'ignores a closed solicitation' do
    create(:solicitation, user: user, status: :closed, created_at: 5.days.ago)

    expect(described_class.for(user)).to be_nil
  end

  it 'ignores contributions' do
    create(:contribution, user: user, created_at: 5.days.ago)

    expect(described_class.for(user)).to be_nil
  end
end

RSpec.describe NextSteps::Exclusions do
  let(:user) { create(:public_user) }
  let(:neighborhood) { create(:neighborhood) }

  def exclusions placement = :hero
    described_class.new(user, placement: placement)
  end

  def proposed kind:, target: nil, displayed_at: Time.zone.now, **attributes
    create(:next_step, user: user, kind: kind, target_type: target&.class&.name, target_id: target&.id,
      first_displayed_at: displayed_at, expires_at: displayed_at + 3.days, **attributes)
  end

  describe 'engine history' do
    it 'excludes a hero proposed 20 days ago that expired untreated' do
      proposed(kind: 'neighborhood', target: neighborhood, displayed_at: 20.days.ago, status: 'expired')

      expect(exclusions.excluded_target_ids('neighborhood')).to eq([neighborhood.id])
    end

    it 'lets an ignored suggestion come back after 30 days' do
      proposed(kind: 'neighborhood', target: neighborhood, displayed_at: 36.days.ago, status: 'ignored', ignored_at: 35.days.ago)

      expect(exclusions.excluded_target_ids('neighborhood')).to be_empty
    end

    it 'never proposes again a suggestion realised by a tap' do
      proposed(kind: 'poi', target: create(:poi), displayed_at: 90.days.ago, status: 'realised', realised_at: 90.days.ago)

      expect(exclusions.excluded_target_ids('poi')).to be_present
    end

    it 'does not count the 30-day window of heroes for the others, only the active hero and recent ignores' do
      proposed(kind: 'neighborhood', target: neighborhood, displayed_at: 10.days.ago, status: 'expired')

      expect(exclusions(:others).excluded_target_ids('neighborhood')).to be_empty
    end

    it 'excludes the active hero from the others' do
      proposed(kind: 'neighborhood', target: neighborhood)

      expect(exclusions(:others).excluded_target_ids('neighborhood')).to eq([neighborhood.id])
    end

    it 'excludes from the others a suggestion ignored 10 days ago' do
      proposed(kind: 'neighborhood', target: neighborhood, displayed_at: 11.days.ago, status: 'ignored', ignored_at: 10.days.ago)

      expect(exclusions(:others).excluded_target_ids('neighborhood')).to eq([neighborhood.id])
    end
  end

  describe 'domain data' do
    it 'never suggests a group joined outside the engine' do
      create(:join_request, user: user, joinable: neighborhood, status: :accepted)

      expect(exclusions.joined_neighborhood_ids).to include(neighborhood.id)
    end

    it 'never proposes again a content read in the library, even after 30 days' do
      resource = create(:resource)
      create(:users_resource, user: user, resource: resource, watched: true, created_at: 60.days.ago)

      expect(exclusions.excluded_resource_ids).to eq([resource.id])
    end

    it 'excludes the Bonnes ondes requested 10 days ago only' do
      create(:user_smalltalk, user: user, created_at: 10.days.ago)

      expect(exclusions.smalltalk_recently_requested?).to be(true)
    end

    it 'lets the Bonnes ondes come back 30 days after the last request' do
      create(:user_smalltalk, user: user, created_at: 40.days.ago)

      expect(exclusions.smalltalk_recently_requested?).to be(false)
    end

    it 'considers an entraide answered once the user wrote to its author after it was created' do
      author = create(:public_user)
      action = create(:solicitation, user: author, created_at: 2.days.ago)
      conversation = create(:conversation, user: user, participants: [user, author])
      create(:chat_message, messageable: conversation, user: user, created_at: 1.day.ago)

      expect(exclusions.answered_action?(Action.find(action.id))).to be(true)
    end

    it 'does not consider an entraide answered by a message written before it was created' do
      author = create(:public_user)
      conversation = create(:conversation, user: user, participants: [user, author])
      create(:chat_message, messageable: conversation, user: user, created_at: 10.days.ago)
      action = create(:solicitation, user: author, created_at: 2.days.ago)

      expect(exclusions.answered_action?(Action.find(action.id))).to be(false)
    end

    it 'lists the users in a block relation, both ways' do
      blocked = create(:public_user)
      blocking = create(:public_user)
      create(:user_blocked_user, user: user, blocked_user: blocked)
      create(:user_blocked_user, user: blocking, blocked_user: user)

      expect(exclusions.blocked_user_ids).to contain_exactly(blocked.id, blocking.id)
    end
  end
end
