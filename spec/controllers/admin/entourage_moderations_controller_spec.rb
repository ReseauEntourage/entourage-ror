require 'rails_helper'
include AuthHelper

describe Admin::EntourageModerationsController do
  let!(:user) { admin_basic_login }

  describe "POST create/update" do
    let(:entourage) { create(:entourage) }
    let(:result) { entourage.moderation }

    before {
      post :create, params: { entourage_moderation: {
        entourage_id: entourage.id,
        section: "social",
        moderated_at: Time.now,
        moderator_id: user.id,
        moderation_comment: "foobar",
        action_outcome_reported_at: Time.now,
        action_outcome: 'Non',
      }, user: {
        targeting_profile: ""
      }, close_message: ""
    }}

    it { expect(response.status).to eq(200) }
    it { expect(result).not_to be_nil }
    it { expect(result.section_list).to eq("social") }
    it { expect(result.moderation_comment).to eq("foobar") }
  end
end
