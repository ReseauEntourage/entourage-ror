require 'rails_helper'
include AuthHelper

describe Admin::DashboardController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  # le tableau de bord est fait de compteurs ; ses deux listes sont les modérateurs les plus
  # chargés (5 au plus) et les derniers blocages (10 au plus)
  def populate(count)
    count.times do
      moderator = create :public_user, admin: true, roles: [:moderator], first_name: "Modérateur #{SecureRandom.hex(4)}"
      action = create :entourage, title: "Action #{SecureRandom.hex(4)}", user: create(:public_user)
      action.moderation.update!(moderator: moderator)

      create :user_history, kind: 'block', user: create(:public_user), updater: create(:public_user, admin: true)
    end
  end

  def perform_request
    get :index
  end

  def returned_items_count
    assigns(:busiest_moderators).size + assigns(:recent_blocks).size
  end

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 sur les modérateurs les plus chargés (ModerationServices.workload_rows : 2 COUNT par modérateur, tous calculés avant first(5))'
  end
end
