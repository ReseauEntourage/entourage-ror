require 'rails_helper'

describe Api::V1::Neighborhoods::ChatMessagesController, type: :controller do
  let(:user) { create :pro_user }
  let(:neighborhood) { create :neighborhood, participants: [user] }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 : partners des auteurs (GenericSerializer#user appelle object.user.partner, :user est préchargé mais pas user: :partner)' do
      def populate(count)
        count.times do
          author = create :public_user, partner: create(:partner, name: "Partenaire #{SecureRandom.hex(4)}"), avatar_key: "avatar-#{SecureRandom.hex(4)}", partner_role_title: 'Bénévole'
          create :join_request, joinable: neighborhood, user: author, status: :accepted

          post = create :chat_message,
            messageable: neighborhood,
            user: author,
            image_url: "image-#{SecureRandom.hex(4)}.jpg",
            content: "post #{SecureRandom.hex(4)}",
            survey: create(:survey)

          translation = Translation.find_or_initialize_by(instance: post)
          translation.update!(fr: { content: post.content }, en: { content: "en #{post.content}" })

          # commentaire (comments_count / has_comments)
          create :chat_message, messageable: neighborhood, user: create(:public_user), parent: post, content: "comment #{SecureRandom.hex(4)}"

          # réactions (summary + reaction_id de l'utilisateur courant)
          create :user_reaction, instance: post, user: create(:public_user), reaction: create(:reaction)
          create :user_reaction, instance: post, user: user, reaction: create(:reaction)

          # réponses au sondage (survey_response de l'utilisateur courant)
          create :survey_response, chat_message: post, user: create(:public_user), responses: [true, false]
          create :survey_response, chat_message: post, user: user, responses: [false, true]
        end
      end

      def perform_request
        get :index, params: { neighborhood_id: neighborhood.to_param, token: user.token, per: 50 }
      end

      def returned_items_count
        JSON.parse(response.body)['chat_messages'].size
      end
    end
  end
end
