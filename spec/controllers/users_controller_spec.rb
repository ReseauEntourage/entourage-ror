require 'rails_helper'

describe UsersController, :type => :controller do

  describe 'users enrollment' do
    let!(:user) { create :user }
    subject { assigns(:user) }

    context 'when user already exists' do
      let(:another_user) { create :user, email: 'another_user@mail.com' }
      before { post 'validation', email: another_user.email, format: 'json' }
      it { should eq another_user }
    end

    context 'when user does not exist' do
      before { post 'validation', email: 'not_existing@nowhere.com', format: 'json' }
      it { should be nil }
    end

  end

end
