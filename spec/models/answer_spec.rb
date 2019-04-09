require 'rails_helper'

RSpec.describe Answer, type: :model  do
  it { expect(FactoryGirl.build(:answer).save).to be true }
  it { should belong_to :question }
  it { should belong_to :encounter }
  it { should validate_presence_of :question_id }
  it { should validate_presence_of :encounter_id }
  it { should validate_presence_of :value }
end
