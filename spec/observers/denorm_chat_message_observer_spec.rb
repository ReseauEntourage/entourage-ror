require 'rails_helper'

RSpec.describe DenormChatMessageObserver do
  let(:user)   { create(:pro_user) }
  let(:outing) { create(:outing) }
  let!(:membership) { create(:join_request, joinable: outing, user: user, status: 'accepted') }

  describe "broadcast ActionCable sur création d'un message dans un outing" do
    context "message texte standard" do
      it "diffuse sur le canal de l'outing" do
        expect {
          create(:chat_message, messageable: outing, user: user, content: "Hello !")
        }.to have_broadcasted_to("outing_chat:#{outing.id}")
          .with(hash_including(
            type:      "new_message",
            outing_id: outing.id,
            user_id:   user.id
          ))
      end
    end

    context "status_update (ex: outing fermé)" do
      it "ne diffuse pas" do
        expect {
          create(:chat_message, :closed_as_success, messageable: outing, user: user)
        }.not_to have_broadcasted_to("outing_chat:#{outing.id}")
      end
    end

    context "message dans un entourage non-outing (action)" do
      let(:action) { create(:entourage, group_type: :action) }

      it "ne diffuse pas" do
        expect {
          create(:chat_message, messageable: action, user: user, content: "Hello")
        }.not_to have_broadcasted_to("outing_chat:#{action.id}")
      end
    end
  end
end
