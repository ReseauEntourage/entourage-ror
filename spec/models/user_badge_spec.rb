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
end
