require 'rails_helper'

RSpec.describe EntourageScore, type: :model do
  it { expect(FactoryBot.build(:entourage_score).save).to be true }
  it { should belong_to :entourage }
  it { should belong_to :user }
  it { should validate_presence_of :entourage_id }
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :base_score }
  it { should validate_presence_of :final_score }
end
