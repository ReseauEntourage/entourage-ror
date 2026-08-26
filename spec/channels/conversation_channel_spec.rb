require 'rails_helper'

RSpec.describe ConversationChannel, type: :channel do
  let(:user)         { create(:pro_user) }
  let(:outing)       { create(:outing) }
  let(:neighborhood) { create(:neighborhood) }
  let(:conversation) { create(:conversation) }
  let(:smalltalk)    { create(:smalltalk) }
  let(:solicitation) { create(:solicitation) }
  let(:contribution) { create(:contribution) }

  def join(joinable, status: 'accepted')
    create(:join_request, joinable: joinable, user: user, status: status)
  end

  # ─── Abonnement à un outing ─────────────────────────────────────────────────

  describe "subscribed — outing" do
    before { stub_connection current_user: user }

    context "membre accepté" do
      before { join(outing) }

      it "confirme l'abonnement" do
        subscribe(instance_type: "Outing", instance_id: outing.id)
        expect(subscription).to be_confirmed
      end

      it "streame sur conversation:Outing:{id}" do
        subscribe(instance_type: "Outing", instance_id: outing.id)
        expect(subscription.streams).to include("conversation:Outing:#{outing.id}")
      end
    end

    context "non membre" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Outing", instance_id: outing.id)
        expect(subscription).to be_rejected
      end
    end

    context "membre en attente" do
      before { join(outing, status: 'pending') }

      it "rejette l'abonnement" do
        subscribe(instance_type: "Outing", instance_id: outing.id)
        expect(subscription).to be_rejected
      end
    end

    context "outing inexistant" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Outing", instance_id: 999_999)
        expect(subscription).to be_rejected
      end
    end

    context "abonnement via l'ancien type générique \"Entourage\"" do
      before { join(outing) }

      it "rejette l'abonnement" do
        subscribe(instance_type: "Entourage", instance_id: outing.id)
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
        subscribe(instance_type: "Conversation", instance_id: conversation.id)
        expect(subscription).to be_confirmed
      end

      it "streame sur conversation:Conversation:{id}" do
        subscribe(instance_type: "Conversation", instance_id: conversation.id)
        expect(subscription.streams).to include("conversation:Conversation:#{conversation.id}")
      end
    end

    context "non participant" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Conversation", instance_id: conversation.id)
        expect(subscription).to be_rejected
      end
    end
  end

  # ─── Abonnement à un smalltalk ──────────────────────────────────────────────

  describe "subscribed — smalltalk" do
    before { stub_connection current_user: user }

    context "participant accepté" do
      before { join(smalltalk) }

      it "confirme l'abonnement" do
        subscribe(instance_type: "Smalltalk", instance_id: smalltalk.id)
        expect(subscription).to be_confirmed
      end

      it "streame sur conversation:Smalltalk:{id}" do
        subscribe(instance_type: "Smalltalk", instance_id: smalltalk.id)
        expect(subscription.streams).to include("conversation:Smalltalk:#{smalltalk.id}")
      end
    end

    context "non participant" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Smalltalk", instance_id: smalltalk.id)
        expect(subscription).to be_rejected
      end
    end
  end

  # ─── Abonnement à une solicitation ("action" / ask_for_help) ────────────────

  describe "subscribed — solicitation" do
    before { stub_connection current_user: user }

    context "membre accepté" do
      before { join(solicitation) }

      it "confirme l'abonnement" do
        subscribe(instance_type: "Solicitation", instance_id: solicitation.id)
        expect(subscription).to be_confirmed
      end

      it "streame sur conversation:Solicitation:{id}" do
        subscribe(instance_type: "Solicitation", instance_id: solicitation.id)
        expect(subscription.streams).to include("conversation:Solicitation:#{solicitation.id}")
      end
    end

    context "non membre" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Solicitation", instance_id: solicitation.id)
        expect(subscription).to be_rejected
      end
    end

    context "abonnement d'une contribution via le type \"Solicitation\"" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Solicitation", instance_id: contribution.id)
        expect(subscription).to be_rejected
      end
    end
  end

  # ─── Abonnement à une contribution ("action" / contribution) ────────────────

  describe "subscribed — contribution" do
    before { stub_connection current_user: user }

    context "membre accepté" do
      before { join(contribution) }

      it "confirme l'abonnement" do
        subscribe(instance_type: "Contribution", instance_id: contribution.id)
        expect(subscription).to be_confirmed
      end

      it "streame sur conversation:Contribution:{id}" do
        subscribe(instance_type: "Contribution", instance_id: contribution.id)
        expect(subscription.streams).to include("conversation:Contribution:#{contribution.id}")
      end
    end

    context "non membre" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Contribution", instance_id: contribution.id)
        expect(subscription).to be_rejected
      end
    end

    context "abonnement d'une solicitation via le type \"Contribution\"" do
      it "rejette l'abonnement" do
        subscribe(instance_type: "Contribution", instance_id: solicitation.id)
        expect(subscription).to be_rejected
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

    it "rejette le type générique \"Action\"" do
      subscribe(instance_type: "Action", instance_id: solicitation.id)
      expect(subscription).to be_rejected
    end
  end

  # ─── Broadcasts — outing ─────────────────────────────────────────────────────

  describe ".broadcast_chat_message_created" do
    let!(:message) { create(:chat_message, messageable: outing, user: user, content: "Bonjour !") }

    it "diffuse sur le stream de l'outing avec le bon type" do
      expect {
        ConversationChannel.broadcast_chat_message_created(message)
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
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
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(data: hash_including("id" => message.id)))
    end
  end

  describe ".broadcast_chat_message_updated" do
    let!(:message) { create(:chat_message, messageable: outing, user: user, content: "Contenu") }

    it "diffuse sur le stream de l'outing avec le bon type" do
      expect {
        ConversationChannel.broadcast_chat_message_updated(message)
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
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
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(
          type:          "user_reaction_added",
          user_id:       user.id,
          instance_type: "UserReaction"
        ))
    end

    it "inclut reaction_id et chat_message_id dans les données" do
      expect {
        ConversationChannel.broadcast_user_reaction_added(user_reaction, message)
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
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
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(type: "user_reaction_removed", user_id: user.id))
    end
  end

  describe ".broadcast_member_joined" do
    let!(:join_request) { create(:join_request, joinable: outing, user: user, status: 'accepted') }

    it "diffuse sur le stream de l'outing avec le type member_joined" do
      expect {
        ConversationChannel.broadcast_member_joined(join_request)
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(
          type:          "member_joined",
          user_id:       user.id,
          instance_type: "JoinRequest",
          instance_id:   join_request.id
        ))
    end

    it "inclut les données sérialisées du membre" do
      expect {
        ConversationChannel.broadcast_member_joined(join_request)
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(data: hash_including("id" => user.id)))
    end
  end

  describe ".broadcast_member_left" do
    let!(:join_request) { create(:join_request, joinable: outing, user: user, status: 'cancelled') }

    it "diffuse sur le stream de l'outing avec le type member_left" do
      expect {
        ConversationChannel.broadcast_member_left(join_request)
      }.to have_broadcasted_to("conversation:Outing:#{outing.id}")
        .with(hash_including(
          type:          "member_left",
          user_id:       user.id,
          instance_type: "JoinRequest",
          instance_id:   join_request.id
        ))
    end
  end

  # ─── Broadcasts — conversation privée ───────────────────────────────────────

  describe ".broadcast_chat_message_created — conversation privée" do
    let!(:message) { create(:chat_message, messageable: conversation, user: user, content: "Salut !") }

    it "diffuse sur le stream de la conversation avec le bon type" do
      expect {
        ConversationChannel.broadcast_chat_message_created(message)
      }.to have_broadcasted_to("conversation:Conversation:#{conversation.id}")
        .with(hash_including(type: "chat_message_created", instance_type: "ChatMessage"))
    end
  end

  # ─── Broadcasts — solicitation / contribution ───────────────────────────────

  describe ".broadcast_chat_message_created — solicitation" do
    let!(:message) { create(:chat_message, messageable: solicitation, user: user, content: "Besoin d'aide") }

    it "diffuse sur le stream de la solicitation avec le bon type" do
      expect {
        ConversationChannel.broadcast_chat_message_created(message)
      }.to have_broadcasted_to("conversation:Solicitation:#{solicitation.id}")
        .with(hash_including(type: "chat_message_created", instance_type: "ChatMessage"))
    end
  end

  describe ".broadcast_chat_message_created — contribution" do
    let!(:message) { create(:chat_message, messageable: contribution, user: user, content: "Je propose mon aide") }

    it "diffuse sur le stream de la contribution avec le bon type" do
      expect {
        ConversationChannel.broadcast_chat_message_created(message)
      }.to have_broadcasted_to("conversation:Contribution:#{contribution.id}")
        .with(hash_including(type: "chat_message_created", instance_type: "ChatMessage"))
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

  describe ".broadcast_member_joined — neighborhood" do
    let!(:join_request) { create(:join_request, joinable: neighborhood, user: user, status: 'accepted') }

    it "diffuse sur le stream du neighborhood avec le type member_joined" do
      expect {
        ConversationChannel.broadcast_member_joined(join_request)
      }.to have_broadcasted_to("conversation:Neighborhood:#{neighborhood.id}")
        .with(hash_including(type: "member_joined", instance_type: "JoinRequest"))
    end
  end

  describe ".broadcast_member_left — neighborhood" do
    let!(:join_request) { create(:join_request, joinable: neighborhood, user: user, status: 'cancelled') }

    it "diffuse sur le stream du neighborhood avec le type member_left" do
      expect {
        ConversationChannel.broadcast_member_left(join_request)
      }.to have_broadcasted_to("conversation:Neighborhood:#{neighborhood.id}")
        .with(hash_including(type: "member_left", instance_type: "JoinRequest"))
    end
  end

  # ─── Smalltalk broadcast ─────────────────────────────────────────────────────

  describe ".broadcast_chat_message_created — smalltalk" do
    let!(:message) { create(:chat_message, messageable: smalltalk, user: user, content: "Coucou !") }

    it "diffuse sur le stream du smalltalk" do
      expect {
        ConversationChannel.broadcast_chat_message_created(message)
      }.to have_broadcasted_to("conversation:Smalltalk:#{smalltalk.id}")
        .with(hash_including(type: "chat_message_created", instance_type: "ChatMessage"))
    end
  end

  describe ".broadcast_member_joined — smalltalk" do
    let!(:join_request) { create(:join_request, joinable: smalltalk, user: user, status: 'accepted') }

    it "diffuse sur le stream du smalltalk avec le type member_joined" do
      expect {
        ConversationChannel.broadcast_member_joined(join_request)
      }.to have_broadcasted_to("conversation:Smalltalk:#{smalltalk.id}")
        .with(hash_including(type: "member_joined", instance_type: "JoinRequest"))
    end
  end

  # ─── group_type "group" — pas de classe dédiée, pas de websocket ────────────

  describe "stream_type_for — entourage group_type \"group\"" do
    let(:group_entourage) { Entourage.new(group_type: 'group', entourage_type: 'ask_for_help') }

    it "ne résout aucun type de stream" do
      expect(ConversationChannel.send(:stream_type_for, group_entourage)).to be_nil
    end
  end

  # ─── Déconnexion ─────────────────────────────────────────────────────────────

  describe "unsubscribed" do
    before do
      stub_connection current_user: user
      join(outing)
      subscribe(instance_type: "Outing", instance_id: outing.id)
    end

    it "arrête tous les streams" do
      expect { unsubscribe }.not_to raise_error
    end
  end
end
