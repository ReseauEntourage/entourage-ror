require 'rails_helper'

RSpec.describe UserNewsfeed, type: :model do
  it { expect(FactoryBot.build(:user_newsfeed).save).to be true }
  it { should belong_to :user }
  it { should validate_presence_of :latitude }
  it { should validate_presence_of :longitude }
end
