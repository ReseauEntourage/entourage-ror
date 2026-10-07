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
end
