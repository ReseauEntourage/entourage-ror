require 'rails_helper'

RSpec.describe UserBadge, type: :model do
  it { should belong_to(:user) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:badge_tag) }
  it { should validate_presence_of(:awarded_at) }
end
