require 'rails_helper'

describe Api::V1::Smalltalks::ChatMessagesController, type: :controller do
  let(:user) { create :pro_user }
  let(:smalltalk) { create :smalltalk }
  let!(:join_request) { create :join_request, joinable: smalltalk, user: user, status: :accepted }

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries',
      pending: 'N+1 : partners et surveys (includes(:user) sans user: :partner ni :survey)' do
      # chaque message a son propre auteur (avec partenaire), son sondage, son image,
      # sa traduction et ses réactions (dont celle de l'utilisateur courant)
      def populate(count)
        count.times do
          author = create :public_user, partner: create(:partner, name: "partner #{SecureRandom.hex(3)}"),
            avatar_key: "avatar_#{SecureRandom.hex(3)}.jpg", targeting_profile: 'partner', partner_role_title: 'Bénévole'
          create :join_request, joinable: smalltalk, user: author, status: :accepted

          message = create :chat_message, messageable: smalltalk, user: author, image_url: "image_#{SecureRandom.hex(3)}.jpg",
            survey: create(:survey)
          create :translation, instance: message, from_lang: 'fr', fr: { content: message.content }, en: { content: 'translated' } unless message.translation

          reaction = create :reaction, name: "reaction #{SecureRandom.hex(3)}", key: "key_#{SecureRandom.hex(3)}"
          create :user_reaction, instance: message, reaction: reaction, user: user
          create :user_reaction, instance: message, reaction: reaction, user: create(:public_user)
        end
      end

      def perform_request
        get :index, params: { smalltalk_id: smalltalk.to_param, token: user.token }
      end

      def returned_items_count
        JSON.parse(response.body)['chat_messages'].size
      end
    end
  end
end
