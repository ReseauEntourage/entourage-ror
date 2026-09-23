require 'rails_helper'

describe Api::V1::Users::ActionsController, type: :controller do
  let(:user) { create :pro_user, avatar_key: 'avatar-key' }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : sections, traductions et membres (aucun préchargement dans le contrôleur : section_list, translation et member_ids requêtent par action) + image_resize_actions (ActionSerializer#image_url)' do
      # l'endpoint liste les actions de l'utilisateur : l'auteur est donc toujours le même,
      # les autres associations (membres, sections, traductions, image) sont distinctes
      def populate(count)
        count.times do |i|
          factory = i.even? ? :contribution : :solicitation
          action = create factory,
            user: user,
            title: "action #{SecureRandom.hex(4)}",
            description: "description #{SecureRandom.hex(4)}",
            image_url: "contribution-#{SecureRandom.hex(4)}.jpg",
            section_list: ['social'],
            participants: [create(:public_user)]

          translation = Translation.find_or_initialize_by(instance: action)
          translation.update!(fr: { title: action.title, description: action.description }, en: { title: "en #{action.title}", description: "en #{action.description}" })
        end
      end

      def perform_request
        get :index, params: { user_id: user.id, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['actions'].size
      end
    end
  end
end
