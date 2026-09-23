require 'rails_helper'

RSpec.describe UserBadge, type: :model do
  subject { build(:user_badge) }

  it { should belong_to(:user) }
  it { should validate_uniqueness_of(:badge_tag).scoped_to(:user_id) }

  describe 'creation' do
    let(:user) { create(:public_user) }

    it 'saves a valid badge' do
      badge = build(:user_badge, user: user, badge_tag: 'bienvenue')
      expect(badge.save).to be true
    end

    it 'prevents duplicate badge_tag for same user' do
      create(:user_badge, user: user, badge_tag: 'bienvenue')
      duplicate = build(:user_badge, user: user, badge_tag: 'bienvenue')
      expect(duplicate).not_to be_valid
    end

    it 'allows same badge_tag for different users' do
      other_user = create(:public_user)
      create(:user_badge, user: user, badge_tag: 'bienvenue')
      badge = build(:user_badge, user: other_user, badge_tag: 'bienvenue')
      expect(badge).to be_valid
    end

    it 'allows different badge_tags for same user' do
      create(:user_badge, user: user, badge_tag: 'bienvenue')
      badge = build(:user_badge, user: user, badge_tag: 'premier_contact')
      expect(badge).to be_valid
    end
  end

  describe '.all_for_user' do
    let(:user) { create(:public_user) }
    let!(:badge) { create(:user_badge, user: user, badge_tag: 'bienvenue', active: true) }

    def badge_queries
      queries = []
      callback = lambda { |*, payload| queries << payload[:sql] if payload[:sql] =~ /FROM "user_badges"/ }
      result = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { yield }

      [result, queries.size]
    end

    it 'returns every badge tag, existing or not' do
      badges = UserBadge.all_for_user(user)

      expect(badges.map(&:badge_tag)).to eq(UserBadge::ALL_TAGS)
      expect(badges.first).to eq(badge)
      expect(badges.drop(1)).to all(be_new_record)
    end

    it 'uses the user_badges association when it is already loaded' do
      user = User.includes(:user_badges).find(badge.user_id)

      badges, count = badge_queries { UserBadge.all_for_user(user) }

      expect(badges.first).to eq(badge)
      expect(count).to eq(0)
    end

    it 'supports anonymous users' do
      expect(UserBadge.all_for_user(AnonymousUser.default_user).map(&:badge_tag)).to eq(UserBadge::ALL_TAGS)
    end
  end
end
