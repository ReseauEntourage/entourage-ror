require 'rails_helper'

RSpec.describe SuggestionComputeHistory, type: :model do
  it { expect(FactoryBot.build(:suggestion_compute_history).save).to be true }
  it { should validate_presence_of :user_number }
  it { should validate_presence_of :total_user_number }
  it { should validate_presence_of :entourage_number }
  it { should validate_presence_of :total_entourage_number }
  it { should validate_presence_of :duration }
  it { should validate_presence_of :filter_type }
end
