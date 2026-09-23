require 'rails_helper'

describe Api::V1::Entourages::ChatMessagesController, type: :controller do
  let(:user) { create :public_user }
  let(:entourage) { create :entourage }
  let!(:join_request) { create :join_request, joinable: entourage, user: user, status: 'accepted' }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : translations (contrôleur : includes(user: :partner) sans :translation) + image_resize_actions (PartnerSerializer#image_url -> ImageResizeAction.find_path_for, 1 par partenaire distinct)' do
      def populate(count)
        count.times do
          author = create :partner_user, partner: create(:partner, name: "Partner #{SecureRandom.hex(4)}", image_url: "partner_#{SecureRandom.hex(4)}.jpg"), avatar_key: "avatar_#{SecureRandom.hex(4)}"
          create :join_request, joinable: entourage, user: author, status: 'accepted'

          # messages de plus en plus anciens : le plus récent reste celui de populate(1),
          # pour que la mise à jour de last_message_read (constante, hors N+1) ne se
          # déclenche que lors de la requête de chauffe
          message = create :chat_message, messageable: entourage, user: author,
            content: "message #{SecureRandom.hex(4)}", created_at: 1.hour.ago - ChatMessage.count.minutes

          message.translation || create(:translation, instance: message)
        end
      end

      def perform_request
        get :index, params: { entourage_id: entourage.to_param, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['chat_messages'].size
      end
    end
  end
end
