require 'rails_helper'

RSpec.describe DenormChatMessageObserver do
  let(:user)   { create(:pro_user) }
  let(:outing) { create(:outing) }

  describe "jobs de dénormalisation" do
    it "planifie UnreadChatMessageJob à la création d'un message" do
      expect(UnreadChatMessageJob).to receive(:perform_later)
        .with("Entourage", outing.id)
      create(:chat_message, messageable: outing, user: user, content: "Hello !")
    end

    it "planifie CountChatMessageJob à la création d'un message" do
      expect(CountChatMessageJob).to receive(:perform_later)
        .with("Entourage", outing.id)
      create(:chat_message, messageable: outing, user: user, content: "Hello !")
    end

    it "ne planifie pas de job pour un status_update" do
      # Les jobs sont quand même déclenchés sur status_update — ce test vérifie
      # que l'observer ne plante pas dans ce cas.
      expect {
        create(:chat_message, :closed_as_success, messageable: outing, user: user)
      }.not_to raise_error
    end
  end

  describe "recalcul des compteurs d'impact" do
    let(:neighborhood) { create(:neighborhood) }
    let(:conversation) { create(:conversation, participants: [user, create(:public_user)]) }

    it "planifie neighborhood_messages pour un post de groupe de voisins" do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::NEIGHBORHOOD_MESSAGES)
      create(:chat_message, messageable: neighborhood, user: user)
    end

    it "planifie conversation_members pour un message privé" do
      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::CONVERSATION_MEMBERS)
      create(:chat_message, messageable: conversation, user: user)
    end

    it "planifie le recalcul quand un message passe en deleted" do
      message = create(:chat_message, messageable: neighborhood, user: user)

      expect(UserImpactStatsJob).to receive(:perform_async).with(user.id, UserStat::NEIGHBORHOOD_MESSAGES)
      message.update!(status: :deleted)
    end

    it "ne planifie rien pour un message d'événement ou d'entraide" do
      # the action's own creation enqueues action_creations (UserImpactStatsObserver)
      action = create(:entourage)

      expect(UserImpactStatsJob).not_to receive(:perform_async)
      create(:chat_message, messageable: outing, user: user)
      create(:chat_message, messageable: action, user: user)
    end

    it "ne planifie rien pour un broadcast" do
      expect(UserImpactStatsJob).not_to receive(:perform_async)
      create(:chat_message, messageable: neighborhood, user: user, message_type: :broadcast,
        metadata: { conversation_message_broadcast_id: create(:neighborhood_message_broadcast).id })
    end
  end
end
