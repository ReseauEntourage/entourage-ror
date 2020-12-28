require 'rails_helper'

describe Api::V1::QuestionsController do

  let(:user) { FactoryBot.create(:pro_user) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:questions) { FactoryBot.create_list(:question, 2, organization: user.organization) }
      before { get :index, params: { token: user.token } }
      it { expect(JSON.parse(response.body)).to eq({"questions"=>[{"id"=>questions.first.id, "title"=>"MyString", "answer_type"=>"MyString"},
                                                                  {"id"=>questions.last.id, "title"=>"MyString", "answer_type"=>"MyString"}]}) }
    end
  end
end
