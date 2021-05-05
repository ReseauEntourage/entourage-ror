require 'rails_helper'
include AuthHelper

describe QuestionsController do

  describe 'POST create' do
    let(:question_params) {
      { title: "foo", answer_type: "string" }
    }
    context "not logged in" do
      before { post 'create', params: { question: question_params } }
      it { should redirect_to new_session_path }
    end

    context "logged in" do
      let!(:user) { manager_basic_login }

      context "valid params" do
        before { post 'create', params: { question: question_params } }
        it { expect(Question.count).to eq(1) }
        it { should redirect_to edit_organization_path(user.organization) }
      end

      context "invalid params" do
        before { post 'create', params: { question: {title: nil} } }
        it { expect(Question.count).to eq(0) }
        it { should redirect_to edit_organization_path(user.organization) }
      end
    end
  end

  describe "DELETE destroy" do
    let(:question) { FactoryBot.create(:question) }

    context "not logged in" do
      before { delete 'destroy', params: { id: question.to_param } }
      it { should redirect_to new_session_path }
    end

    context "logged in" do
      let!(:user) { manager_basic_login }

      context "valid params" do
        before { delete 'destroy', params: { id: question.to_param } }
        it { expect(Question.count).to eq(0) }
        it { should redirect_to edit_organization_path(user.organization) }
      end
    end
  end
end
