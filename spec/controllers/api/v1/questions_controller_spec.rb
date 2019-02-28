require 'rails_helper'

describe Api::V1::QuestionsController do

  let(:user) { FactoryGirl.create(:pro_user) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:questions) { FactoryGirl.create_list(:question, 2, organization: user.organization) }
      before { get :index, token: user.token }
      it { expect(JSON.parse(response.body)).to eq({"questions"=>[{"id"=>questions.first.id, "title"=>"MyString", "answer_type"=>"MyString"},
                                                                  {"id"=>questions.last.id, "title"=>"MyString", "answer_type"=>"MyString"}]}) }
    end
  end
end
