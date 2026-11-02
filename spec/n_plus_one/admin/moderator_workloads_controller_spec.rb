require 'rails_helper'
include AuthHelper

describe Admin::ModeratorWorkloadsController, type: :controller do
  render_views

  let!(:user) { admin_basic_login }

  # chaque modérateur a une action ouverte qui lui est assignée
  def populate(count)
    count.times do
      moderator = create :public_user, admin: true, roles: [:moderator], first_name: "Modérateur #{SecureRandom.hex(4)}"
      action = create :entourage, title: "Action #{SecureRandom.hex(4)}", user: create(:public_user)
      action.moderation.update!(moderator: moderator)
    end
  end

  def perform_request
    get :index
  end

  def returned_items_count
    assigns(:rows).size
  end

  describe 'GET index' do
    it_behaves_like 'an endpoint without N+1 queries', pending: 'N+1 sur la file de chaque modérateur (ModerationServices.workload_rows : 2 COUNT par modérateur)'
  end
end
