require 'rails_helper'

RSpec.describe Question, type: :model do
  it { expect(FactoryBot.build(:question).save).to be true }
  it { should validate_presence_of :title }
  it { should validate_presence_of :answer_type }
  it { should validate_presence_of :organization_id }
  it { should belong_to :organization }

  context "has already 5 questions for organization" do
    let(:organization) { FactoryBot.create(:organization) }
    before { FactoryBot.create_list(:question, 5, organization: organization) }
    it { expect(FactoryBot.build(:question).save).to be true }
    it { expect(FactoryBot.build(:question, organization: organization).save).to be false }
  end
end
