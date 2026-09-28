require 'rails_helper'
include AuthHelper

describe Admin::EntouragesController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  # NOTE : la vue index plante sans ce stub (bug hors N+1) : index.html.erb:71 appelle
  # `@q.moderation_action_outcome_blank`, or Ransack 4 exige que l'association `moderation`
  # soit déclarée dans `Entourage.ransackable_associations` et `action_outcome` dans
  # `EntourageModeration.ransackable_attributes` (non définies => RuntimeError).
  # On les déclare ici uniquement pour pouvoir rendre la vue et y mesurer les requêtes.
  before do
    allow(Entourage).to receive(:ransackable_associations).and_return(['moderation'])
    allow(EntourageModeration).to receive(:ransackable_attributes).and_return(['action_outcome'])
  end

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries' do
      def populate(count)
        count.times do
          author = create(:public_user)

          action = create :entourage, :joined, user: author, participants: [create(:public_user)]
          create :chat_message, messageable: action, user: author
          EntourageModeration.find_or_initialize_by(entourage_id: action.id).update!(moderated_at: Time.current)
          create :moderator_read, moderatable: action, user: user, read_at: 1.day.ago

          outing = create :outing, :joined, user: create(:public_user), participants: [create(:public_user)]
          create :chat_message, messageable: outing, user: outing.user
        end
      end

      def perform_request
        get :index, params: { moderator_id: :any }
      end

      def returned_items_count
        assigns(:entourages).to_a.size
      end
    end
  end
end
