require 'rails_helper'

RSpec.describe ConversationBroadcastObserver do
  let(:user)         { create(:pro_user) }
  let(:outing)       { create(:outing) }
  let(:neighborhood) { create(:neighborhood) }
  let(:reaction)     { create(:reaction) }

  # ─── ChatMessage créé ────────────────────────────────────────────────────────

  describe "chat_message_created" do
    context "message texte dans un outing" do
      it "diffuse chat_message_created sur le stream de l'outing" do
        expect {
          create(:chat_message, messageable: outing, user: user, content: "Hello !")
        }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
          .with(hash_including(
            type:          "chat_message_created",
            user_id:       user.id,
            instance_type: "ChatMessage"
          ))
      end
    end

    context "message dans un neighborhood" do
      it "diffuse chat_message_created sur le stream du neighborhood" do
        expect {
          create(:chat_message, messageable: neighborhood, user: user, content: "Voisins !")
        }.to have_broadcasted_to("conversation:Neighborhood:#{neighborhood.id}")
          .with(hash_including(type: "chat_message_created"))
      end
    end

    context "status_update (ex: outing fermé)" do
      it "ne diffuse pas" do
        expect {
          create(:chat_message, :closed_as_success, messageable: outing, user: user)
        }.not_to have_broadcasted_to("conversation:Outing:#{outing.id}")
      end
    end
  end

  # ─── ChatMessage modifié (statut) ───────────────────────────────────────────

  describe "chat_message_updated — changement de statut" do
    let!(:message) { create(:chat_message, messageable: outing, user: user, content: "Contenu") }

    it "diffuse chat_message_updated quand le statut change" do
      expect {
        message.update!(status: :offensive)
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(
          type:          "chat_message_updated",
          user_id:       user.id,
          instance_type: "ChatMessage",
          instance_id:   message.id
        ))
    end

    it "ne diffuse pas si le contenu change sans changer le statut" do
      expect {
        message.update!(content: "Nouveau contenu")
      }.not_to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(type: "chat_message_updated"))
    end
  end

  # ─── UserReaction ajoutée ────────────────────────────────────────────────────

  describe "user_reaction_added" do
    let!(:message) { create(:chat_message, messageable: outing, user: user, content: "Hello") }

    it "diffuse user_reaction_added quand une réaction est créée" do
      expect {
        create(:user_reaction, user: user, reaction: reaction, instance: message)
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(
          type:          "user_reaction_added",
          user_id:       user.id,
          instance_type: "UserReaction",
          data:          hash_including(
            "reaction_id"     => reaction.id,
            "chat_message_id" => message.id
          )
        ))
    end
  end

  # ─── UserReaction supprimée ──────────────────────────────────────────────────

  describe "user_reaction_removed" do
    let!(:message)       { create(:chat_message, messageable: outing, user: user, content: "Hello") }
    let!(:user_reaction) { create(:user_reaction, user: user, reaction: reaction, instance: message) }

    it "diffuse user_reaction_removed quand une réaction est détruite" do
      expect {
        user_reaction.destroy!
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(
          type:    "user_reaction_removed",
          user_id: user.id
        ))
    end
  end

  # ─── JoinRequest — un membre rejoint ─────────────────────────────────────────

  describe "member_joined" do
    context "création directe avec status accepted" do
      it "diffuse member_joined sur le stream de l'outing" do
        expect {
          create(:join_request, joinable: outing, user: user, status: 'accepted')
        }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
          .with(hash_including(
            type:          "member_joined",
            user_id:       user.id,
            instance_type: "JoinRequest"
          ))
      end
    end

    context "création avec status pending" do
      it "ne diffuse pas" do
        expect {
          create(:join_request, joinable: outing, user: user, status: 'pending')
        }.not_to have_broadcasted_to("conversation:Outing:#{outing.id}")
          .with(hash_including(type: "member_joined"))
      end
    end

    context "passage de pending à accepted" do
      let!(:join_request) { create(:join_request, joinable: outing, user: user, status: 'pending') }

      it "diffuse member_joined sur le stream de l'outing" do
        expect {
          join_request.update!(status: 'accepted')
        }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
          .with(hash_including(
            type:          "member_joined",
            user_id:       user.id,
            instance_type: "JoinRequest",
            instance_id:   join_request.id
          ))
      end
    end

    context "message dans un neighborhood" do
      it "diffuse member_joined sur le stream du neighborhood" do
        expect {
          create(:join_request, joinable: neighborhood, user: user, status: 'accepted')
        }.to have_broadcasted_to("conversation:Neighborhood:#{neighborhood.id}")
          .with(hash_including(type: "member_joined"))
      end
    end
  end

  # ─── JoinRequest — un membre quitte ──────────────────────────────────────────

  describe "member_left" do
    context "passage de accepted à cancelled (quitte de son propre chef)" do
      let!(:join_request) { create(:join_request, joinable: outing, user: user, status: 'accepted') }

      it "diffuse member_left sur le stream de l'outing" do
        expect {
          join_request.update!(status: 'cancelled')
        }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
          .with(hash_including(
            type:          "member_left",
            user_id:       user.id,
            instance_type: "JoinRequest",
            instance_id:   join_request.id
          ))
      end
    end

    context "passage de accepted à rejected (exclu par un organisateur)" do
      let!(:join_request) { create(:join_request, joinable: outing, user: user, status: 'accepted') }

      it "diffuse member_left sur le stream de l'outing" do
        expect {
          join_request.update!(status: 'rejected')
        }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
          .with(hash_including(type: "member_left"))
      end
    end

    context "passage de pending à rejected (jamais devenu membre)" do
      let!(:join_request) { create(:join_request, joinable: outing, user: user, status: 'pending') }

      it "ne diffuse pas" do
        expect {
          join_request.update!(status: 'rejected')
        }.not_to have_broadcasted_to("conversation:Outing:#{outing.id}")
          .with(hash_including(type: "member_left"))
      end
    end

    context "mise à jour sans changement de statut" do
      let!(:join_request) { create(:join_request, joinable: outing, user: user, status: 'accepted') }

      it "ne diffuse ni member_joined ni member_left" do
        expect {
          join_request.update!(message: "un petit mot")
        }.not_to have_broadcasted_to("conversation:Outing:#{outing.id}")
          .with(hash_including(type: /member_/))
      end
    end
  end
end
