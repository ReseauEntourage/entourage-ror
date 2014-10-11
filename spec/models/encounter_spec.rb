require 'rails_helper'

RSpec.describe Encounter, :type => :model do

  it { should validate_presence_of(:date) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:street_person_name) }
  it { should validate_presence_of(:latitude) }
  it { should validate_numericality_of(:latitude) }
  it { should validate_presence_of(:longitude) }
  it { should validate_numericality_of(:longitude) }

  describe 'encounter validation' do
    let!(:valid_encounter) { FactoryGirl.create :valid_encounter }
    context 'should succeed when the fields are not blank' do
      subject { valid_encounter }
      it { should be_valid }
    end
  end
end
