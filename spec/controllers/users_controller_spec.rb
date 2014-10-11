require 'rails_helper'

RSpec.describe UsersController, :type => :controller do

  describe 'users login' do
    let!(:user) { create :user }
    subject { assigns(:user) }

    context 'when user email is valid' do
      let(:another_user) { create :user, email: 'another_user@mail.com' }
      before { post 'login', email: another_user.email, format: 'json' }
      it { should eq another_user }
    end

    context 'when user does not exist' do
      before { post 'login', email: 'not_existing@nowhere.com', format: 'json' }
      it { should be nil }
    end

  end

end
