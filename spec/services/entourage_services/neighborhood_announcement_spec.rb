require 'rails_helper'
include CommunityHelper

describe EntourageServices::NeighborhoodAnnouncement do
  with_community :pfp

  let!(:user) { create :public_user }
  let!(:neighborhood) { create :neighborhood, :joined, join_request_user: user }
  let!(:outing) { create(:outing, user: user, metadata: {starts_at: Time.zone.local(2018, 7, 26, 19)}).reload }
  let(:chat_message) { neighborhood.chat_messages.last }

  describe ".on_create" do
    before { EntourageServices::NeighborhoodAnnouncement.on_create(outing) }

    it { expect(V1::ChatMessageSerializer.new(chat_message).as_json).to eq(
      'chat_message' => {
        id: chat_message.id,
        content: "a créé une sortie :\nfoobar\nle 26/07 à 19h00,\nCafé la Renaissance, 44 rue de l’Assomption, 75016 Paris",
        user: {
          id: user.id,
          avatar_url: nil,
          display_name: "John D.",
          partner: nil
        },
        created_at: chat_message.created_at,
        message_type: 'outing',
        metadata: {
          uuid: outing.uuid_v2,
          title: "foobar",
          operation: 'created',
          starts_at: outing.metadata[:starts_at],
          display_address: "Café la Renaissance, 44 rue de l’Assomption, 75016 Paris"
        }
      })
    }
  end

  describe ".on_update" do
    before do
      outing.update(title: "plop")
      EntourageServices::NeighborhoodAnnouncement.on_update(outing)
    end

    it { expect(V1::ChatMessageSerializer.new(chat_message).as_json).to eq(
      'chat_message' => {
        id: chat_message.id,
        content: "a modifié une sortie :\nplop\nle 26/07 à 19h00,\nCafé la Renaissance, 44 rue de l’Assomption, 75016 Paris",
        user: {
          id: user.id,
          avatar_url: nil,
          display_name: "John D.",
          partner: nil
        },
        created_at: chat_message.created_at,
        message_type: 'outing',
        metadata: {
          uuid: outing.uuid_v2,
          title: "plop",
          operation: 'updated',
          starts_at: outing.metadata[:starts_at],
          display_address: "Café la Renaissance, 44 rue de l’Assomption, 75016 Paris"
        }
      })
    }
  end
end
