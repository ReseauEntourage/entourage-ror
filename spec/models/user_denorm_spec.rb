require 'rails_helper'

RSpec.describe UserDenorm, type: :model do
  include ActiveJob::TestHelper

  # after_create
  describe "after_create entourage" do
    let(:user) { create :public_user }

    describe "creates a denorm if action" do
      let!(:action) { create :entourage, user: user }

      it do
        action
        denorm = UserDenorm.find_by(user_id: user.id)

        expect(denorm).to be_kind_of UserDenorm
        expect(denorm.last_created_action_id).to eq(action.id)
      end
    end

    describe "does not create a denorm if group" do
      let!(:group) { create :entourage, group_type: :group, user: user }

      it do
        denorm = UserDenorm.find_by(user_id: user.id)

        expect(denorm).to eq nil
      end
    end
  end

  describe "after_create join_request" do
    let(:user) { create :public_user }

    describe "creates a denorm if action" do
      let(:action) { create :entourage }
      let!(:join_request) { create :join_request, joinable: action, user_id: user.id }

      it do
        denorm = UserDenorm.find_by(user_id: user.id)

        expect(denorm).to be_kind_of UserDenorm
        expect(denorm.last_join_request_id).to eq(join_request.id)
      end
    end

    describe "does not create a denorm if group" do
      let!(:group) { create :entourage, group_type: :group, user: user }
      let!(:join_request) { create :join_request, joinable: group, user_id: user.id, status: :accepted }

      it do
        denorm = UserDenorm.find_by(user_id: user.id)

        expect(denorm).to eq nil
      end
    end

    describe "does not create a denorm if rejected" do
      let(:action) { create :entourage }
      let!(:join_request) { create :join_request, joinable: action, user_id: user.id, status: :rejected }

      it do
        puts UserDenorm.find_by(user_id: user.id).inspect
        denorm = UserDenorm.find_by(user_id: user.id)

        expect(denorm).to eq nil
      end
    end
  end

  describe "after_create chat_message" do
    let(:user) { create :public_user }

    describe "creates a denorm if action" do
      let(:action) { create :entourage }
      let!(:chat_message) { create :chat_message, messageable: action, user_id: user.id }

      it do
        denorm = UserDenorm.find_by(user_id: user.id)

        expect(denorm).to be_kind_of UserDenorm
        expect(denorm.last_group_chat_message_id).to eq(chat_message.id)
      end
    end

    describe "creates a denorm if conversation" do
      let(:conversation) { create :conversation }
      let!(:chat_message) { create :chat_message, messageable: conversation, user_id: user.id }

      it do
        denorm = UserDenorm.find_by(user_id: user.id)

        expect(denorm).to be_kind_of UserDenorm
        expect(denorm.last_private_chat_message_id).to eq(chat_message.id)
      end
    end

    describe "does not create a denorm if group" do
      let!(:group) { create :entourage, group_type: :group, user: user }
      let!(:chat_message) { create :chat_message, messageable: group, user_id: user.id }

      it do
        denorm = UserDenorm.find_by(user_id: user.id)

        expect(denorm).to eq nil
      end
    end
  end

  # after_update
  describe "after_update entourage" do
    let(:pro) { create :pro_user }
    let(:user) { create :public_user }
    let!(:action) { create :entourage, user: pro }
    let!(:join_request) { create :join_request, joinable: action, user_id: user.id }
    let!(:chat_message) { create :chat_message, messageable: action, user_id: user.id }

    # prerequisite
    it do
      # denorm_pro
      denorm_pro = UserDenorm.find_by(user_id: pro.id)
      expect(denorm_pro).to be_kind_of UserDenorm
      expect(denorm_pro.last_created_action_id).to eq(action.id)
      expect(denorm_pro.last_join_request_id).to eq(nil)
      expect(denorm_pro.last_private_chat_message_id).to eq(nil)
      expect(denorm_pro.last_group_chat_message_id).to eq(nil)
      # denorm_user
      denorm_user = UserDenorm.find_by(user_id: user.id)
      expect(denorm_user).to be_kind_of UserDenorm
      expect(denorm_user.last_created_action_id).to eq(nil)
      expect(denorm_user.last_join_request_id).to eq(join_request.id)
      expect(denorm_user.last_private_chat_message_id).to eq(nil)
      expect(denorm_user.last_group_chat_message_id).to eq(chat_message.id)
    end

    describe "updates a denorm if action" do
      it do
        # we update to group
        # group entourages are not considered in engagement computation; everything should be nil
        expect(UserDenormJob).to receive(:perform_later).with(action.id, nil)

        action.update_attribute(:group_type, :group)

        # calls explicitely
        perform_enqueued_jobs do
          UserDenormJob.new.perform(action.id, nil)
        end

        # denorm_pro
        denorm_pro = UserDenorm.find_by(user_id: pro.id)
        expect(denorm_pro).to be_kind_of UserDenorm
        expect(denorm_pro.last_created_action_id).to eq(nil)
        expect(denorm_pro.last_join_request_id).to eq(nil)
        expect(denorm_pro.last_private_chat_message_id).to eq(nil)
        expect(denorm_pro.last_group_chat_message_id).to eq(nil)
        # denorm_user
        denorm_user = UserDenorm.find_by(user_id: user.id)
        expect(denorm_user).to be_kind_of UserDenorm
        expect(denorm_user.last_created_action_id).to eq(nil)
        expect(denorm_user.last_join_request_id).to eq(nil)
        expect(denorm_user.last_private_chat_message_id).to eq(nil)
        expect(denorm_user.last_group_chat_message_id).to eq(nil)

        # then we update back to action
        # expectations are that we should go back to initial state
        expect(UserDenormJob).to receive(:perform_later).with(action.id, nil)

        action.update_attribute(:group_type, :action)

        perform_enqueued_jobs do
          UserDenormJob.new.perform(action.id, nil)
        end

        # denorm_pro
        denorm_pro = UserDenorm.find_by(user_id: pro.id)
        expect(denorm_pro).to be_kind_of UserDenorm
        expect(denorm_pro.last_created_action_id).to eq(action.id)
        expect(denorm_pro.last_join_request_id).to eq(nil)
        expect(denorm_pro.last_private_chat_message_id).to eq(nil)
        expect(denorm_pro.last_group_chat_message_id).to eq(nil)
        # denorm_user
        denorm_user = UserDenorm.find_by(user_id: user.id)
        expect(denorm_user).to be_kind_of UserDenorm
        expect(denorm_user.last_created_action_id).to eq(nil)
        expect(denorm_user.last_join_request_id).to eq(join_request.id)
        expect(denorm_user.last_private_chat_message_id).to eq(nil)
        expect(denorm_user.last_group_chat_message_id).to eq(chat_message.id)
      end
    end
  end
end
