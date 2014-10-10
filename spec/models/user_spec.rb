require 'rails_helper'

describe User, :type => :model do

  describe 'user validation' do
    let!(:old_user) { FactoryGirl.create :user }
    subject { new_user }

    context 'should fail with already existing email' do
      let(:new_user) { FactoryGirl.build :user }
      it { should_not be_valid }
    end

    context 'should succeed with new email' do
      let(:new_user) { FactoryGirl.build :user, email: "mail_not_existing@mail.com" }
      it { should be_valid }
    end
  end

end