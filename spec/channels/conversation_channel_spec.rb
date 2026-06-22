require 'rails_helper'

RSpec.describe ConversationChannel, type: :channel do
  let(:user)         { create(:pro_user) }
  let(:outing)       { create(:outing) }
  let(:neighborhood) { create(:neighborhood) }
  let(:conversation) { create(:conversation) }

  def join(joinable, status: 'accepted')
    create(:join_request, joinable: joinable, user: user, status: status)
  end

  # ─── Abonnement à un outing ─────────────────────────────────────────────────

  describe "subscribed — outing" do
    before { stub_connection current_user: user }

    context "membre accepté" do
      before { join(outing) }

      it "confirme l'abonnement" do
        subscribe(instance_type: "Entourage", instance_id: outing.id)
        expect(subscription).to be_confirmed
      end

      it "streame sur conversation:Entourage:{id}" do
        subscribe(instance_type: "Entourage", instance_id: outing.id)
        expect(subscription.streams).to include("conversation:Entourage:#{outing.id}")
      end
    end

    context "non membre" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Entourage", instance_id: outing.id)
        expect(subscription).to be_rejected
      end
    end

    context "membre en attente" do
      before { join(outing, status: 'pending') }

      it "rejette l'abonnement" do
        subscribe(instance_type: "Entourage", instance_id: outing.id)
        expect(subscription).to be_rejected
      end
    end

    context "entourage inexistant" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Entourage", instance_id: 999_999)
        expect(subscription).to be_rejected
      end
    end
  end

  # ─── Abonnement à un neighborhood ───────────────────────────────────────────

  describe "subscribed — neighborhood" do
    before { stub_connection current_user: user }

    context "membre accepté" do
      before { join(neighborhood) }

      it "confirme l'abonnement" do
        subscribe(instance_type: "Neighborhood", instance_id: neighborhood.id)
        expect(subscription).to be_confirmed
      end

      it "streame sur conversation:Neighborhood:{id}" do
        subscribe(instance_type: "Neighborhood", instance_id: neighborhood.id)
        expect(subscription.streams).to include("conversation:Neighborhood:#{neighborhood.id}")
      end
    end

    context "non membre" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Neighborhood", instance_id: neighborhood.id)
        expect(subscription).to be_rejected
      end
    end
  end

  # ─── Abonnement à une conversation privée ───────────────────────────────────

  describe "subscribed — conversation privée" do
    before { stub_connection current_user: user }

    context "participant accepté" do
      before { join(conversation) }

      it "confirme l'abonnement" do
        subscribe(instance_type: "Entourage", instance_id: conversation.id)
        expect(subscription).to be_confirmed
      end

      it "streame sur conversation:Entourage:{id}" do
        subscribe(instance_type: "Entourage", instance_id: conversation.id)
        expect(subscription.streams).to include("conversation:Entourage:#{conversation.id}")
      end
    end
  end

  # ─── instance_type invalide ──────────────────────────────────────────────────

  describe "subscribed — instance_type non autorisé" do
    before { stub_connection current_user: user }

    it "rejette si instance_type est inconnu" do
      subscribe(instance_type: "User", instance_id: user.id)
      expect(subscription).to be_rejected
    end
  end

  # ─── Broadcasts ─────────────────────────────────────────────────────────────

  describe ".broadcast_chat_message_created" do
    let!(:message) { create(:chat_message, messageable: outing, user: user, content: "Bonjour !") }

    it "diffuse sur le stream de l'outing avec le bon type" do
      expect {
        ConversationChannel.broadcast_chat_message_created(message)
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
        .with(hash_including(
          type:          "chat_message_created",
          user_id:       user.id,
          instance_type: "ChatMessage",
          instance_id:   message.id
        ))
    end

    it "inclut les données sérialisées du message" do
      expect {
        ConversationChannel.broadcast_chat_message_created(message)
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
        .with(hash_including(data: hash_including("id" => message.id)))
    end
  end

  describe ".broadcast_chat_message_updated" do
    let!(:message) { create(:chat_message, messageable: outing, user: user, content: "Contenu") }

    it "diffuse sur le stream de l'outing avec le bon type" do
      expect {
        ConversationChannel.broadcast_chat_message_updated(message)
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
        .with(hash_including(
          type:          "chat_message_updated",
          user_id:       user.id,
          instance_type: "ChatMessage",
          instance_id:   message.id
        ))
    end
  end

  describe ".broadcast_user_reaction_added" do
    let!(:message)       { create(:chat_message, messageable: outing, user: user) }
    let(:reaction)       { create(:reaction) }
    let!(:user_reaction) { create(:user_reaction, user: user, reaction: reaction, instance: message) }

    it "diffuse sur le stream de l'outing avec le bon type" do
      expect {
        ConversationChannel.broadcast_user_reaction_added(user_reaction, message)
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
        .with(hash_including(
          type:          "user_reaction_added",
          user_id:       user.id,
          instance_type: "UserReaction"
        ))
    end

    it "inclut reaction_id et chat_message_id dans les données" do
      expect {
        ConversationChannel.broadcast_user_reaction_added(user_reaction, message)
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
        .with(hash_including(
          data: hash_including(
            "reaction_id"     => reaction.id,
            "chat_message_id" => message.id
          )
        ))
    end
  end

  describe ".broadcast_user_reaction_removed" do
    let!(:message)       { create(:chat_message, messageable: outing, user: user) }
    let(:reaction)       { create(:reaction) }
    let!(:user_reaction) { create(:user_reaction, user: user, reaction: reaction, instance: message) }

    it "diffuse sur le stream de l'outing avec le type user_reaction_removed" do
      expect {
        ConversationChannel.broadcast_user_reaction_removed(user_reaction, message)
      }.to have_broadcasted_to("conversation:Entourage:#{outing.id}")
        .with(hash_including(type: "user_reaction_removed", user_id: user.id))
    end
  end

  # ─── Neighborhood broadcast ──────────────────────────────────────────────────

  describe ".broadcast_chat_message_created — neighborhood" do
    let!(:message) { create(:chat_message, messageable: neighborhood, user: user, content: "Hello voisins !") }

    it "diffuse sur le stream du neighborhood" do
      expect {
        ConversationChannel.broadcast_chat_message_created(message)
      }.to have_broadcasted_to("conversation:Neighborhood:#{neighborhood.id}")
        .with(hash_including(type: "chat_message_created", instance_type: "ChatMessage"))
    end
  end

  # ─── Déconnexion ─────────────────────────────────────────────────────────────

  describe "unsubscribed" do
    before do
      stub_connection current_user: user
      join(outing)
      subscribe(instance_type: "Entourage", instance_id: outing.id)
    end

    it "arrête tous les streams" do
      expect { unsubscribe }.not_to raise_error
    end
  end
end
