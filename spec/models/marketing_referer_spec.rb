require 'rails_helper'

describe MarketingReferer do
  
  describe 'create' do
    it { expect(FactoryGirl.build(:public_user).save).to eq(true) }
    it { should validate_presence_of :name }
  end
end