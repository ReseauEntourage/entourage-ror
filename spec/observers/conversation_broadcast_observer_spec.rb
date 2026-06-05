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
        }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
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
        }.not_to have_broadcasted_to("conversation:Entourage:#{outing.id}")
      end
    end
  end

  # ─── ChatMessage modifié (statut) ───────────────────────────────────────────

  describe "chat_message_updated — changement de statut" do
    let!(:message) { create(:chat_message, messageable: outing, user: user, content: "Contenu") }

    it "diffuse chat_message_updated quand le statut change" do
      expect {
        message.update!(status: :offensive)
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
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
      }.not_to have_broadcasted_to("conversation:Entourage:#{outing.id}")
        .with(hash_including(type: "chat_message_updated"))
    end
  end

  # ─── UserReaction ajoutée ────────────────────────────────────────────────────

  describe "user_reaction_added" do
    let!(:message) { create(:chat_message, messageable: outing, user: user, content: "Hello") }

    it "diffuse user_reaction_added quand une réaction est créée" do
      expect {
        create(:user_reaction, user: user, reaction: reaction, instance: message)
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
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
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
        .with(hash_including(
          type:    "user_reaction_removed",
          user_id: user.id
        ))
    end
  end
end
