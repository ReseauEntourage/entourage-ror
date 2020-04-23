require 'rails_helper'
include CommunityHelper

describe Api::V1::MyfeedsController do

  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }
      let!(:tour) { FactoryGirl.create(:tour, created_at: 5.hours.ago, tour_type: "medical") }
      let!(:entourage) { FactoryGirl.create(:entourage, created_at: 4.hours.ago, entourage_type: "ask_for_help") }

      context "get entourages i'm not part of" do
        before { get :index, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(result).to eq({"feeds"=>[], "unread_count" => 0}) }
      end

      context "get my entourages" do
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago) }
        let!(:entourage_i_joined) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 2.hour.ago) }
        let!(:entourage_i_canceled) { FactoryGirl.create(:entourage, updated_at: 4.hour.ago) }
        let!(:entourage_i_canceled_join_request) { FactoryGirl.create(:join_request, joinable: entourage_i_canceled, user: user, status: JoinRequest::CANCELLED_STATUS) }
        let!(:entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: FactoryGirl.create(:public_user), updated_at: 3.hour.ago) }
        before { get :index, token: user.token, status: "open" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, entourage_i_joined.id]) }
      end

      context "last_message i'm creator" do
        let!(:entourage) { create :entourage, :joined, user: user }
        context "has pending join_request and messages" do
          context "messages more recent that join requests" do
            let!(:join_request) { create :join_request, joinable: entourage }
            let!(:chat_message) { create :chat_message, messageable: entourage }
            before { get :index, token: user.token }
            it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"1 personne demande à rejoindre votre action.", "author"=>nil}]) }
          end

          context "join requests more recent that messages" do
            let!(:chat_message) { create :chat_message, messageable: entourage }
            let!(:join_request) { create :join_request, joinable: entourage }
            before { get :index, token: user.token }
            it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"1 personne demande à rejoindre votre action.", "author"=>nil}]) }
          end
        end
      end

      context "last_message i'm accepted in" do
        let(:other_user) { create :public_user }
        let!(:entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: other_user, created_at: 1.hour.ago) }
        let!(:tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: other_user, created_at: 1.hour.ago) }

        context "has messages" do
          let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("25/01/2000"), updated_at: DateTime.parse("25/01/2000"), content: "foo") }
          let!(:chat_message2) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("24/01/2000"), updated_at: DateTime.parse("24/01/2000"), content: "bar") }
          let!(:chat_message3) { FactoryGirl.create(:chat_message, messageable: tour, created_at: DateTime.parse("11/01/2000"), updated_at: DateTime.parse("11/01/2000"), content: "tour_foo") }
          before { get :index, token: user.token }
          it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([
            {"text"=>"foo",      "author"=>{"first_name"=>"John", "last_name"=>"D"}},
            {"text"=>"tour_foo", "author"=>{"first_name"=>"John", "last_name"=>"D"}}
          ]) }
        end

        context "has no messages" do
          before { get :index, token: user.token }
          it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([nil, nil]) }
        end

        context "has pending join_request" do
          let!(:join_request) do
            entourage.join_requests.last.update(message: "foo_bar", status: "pending")
          end
          before { get :index, token: user.token }
          it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"Votre demande est en attente.", "author"=>nil}, nil]) }
        end

        context "has pending join_request and messages" do
          context "messages more recent that join requests" do
            let!(:join_request) do
              entourage.join_requests.last.update(message: "foo_bar", status: "pending", created_at: DateTime.parse("10/01/2015"), updated_at: DateTime.parse("10/01/2015"))
            end
            let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("10/01/2016"), updated_at: DateTime.parse("10/01/2016"), content: "foo") }
            before { get :index, token: user.token }
            it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"Votre demande est en attente.", "author"=>nil}, nil]) }
          end

          context "join requests more recent that messages" do
            let!(:join_request) do
              entourage.join_requests.last.update(message: "foo_bar", status: "pending", created_at: DateTime.parse("10/01/2016"), updated_at: DateTime.parse("10/01/2016"))
            end
            let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("10/01/2015"), updated_at: DateTime.parse("10/01/2015"), content: "foo") }
            before { get :index, token: user.token }
            it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"Votre demande est en attente.", "author"=>nil}, nil]) }
          end
        end
      end

      context "last_message i'm not accepted in" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: status) }
        let!(:chat_message) { FactoryGirl.create(:chat_message, messageable: entourage, content: "foo") }
        before { get :index, token: user.token, status: "all" }
        subject { result["feeds"].map {|feed| feed["data"]["last_message"]} }

        context "request is pending" do
          let(:status) { "pending" }
          it { is_expected.to eq [{"text"=>"Votre demande est en attente.", "author"=>nil}] }
        end

        context "request is rejected" do
          let(:status) { "rejected" }
          it { is_expected.to eq [{"text"=>"Votre demande a été rejetée.", "author"=>nil}] }
        end
      end

      context "last_message someone else is pending in" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        let!(:join_request2) { FactoryGirl.create(:join_request, joinable: entourage, status: "pending") }
        before { get :index, token: user.token, status: "all" }
        it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"1 nouvelle demande pour rejoindre votre action.", "author"=>nil}]) }
      end

      context "filter by status" do
        let!(:entourage_open) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, status: :open) }
        let!(:entourage_closed) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 2.hour.ago, status: :closed) }
        let!(:entourage_blacklisted) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 3.hour.ago, status: :blacklisted) }
        let!(:entourage_suspended_by_other) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 4.hour.ago, status: :suspended) }
        let!(:entourage_suspended_by_me) { FactoryGirl.create(:entourage, :joined, user: user, updated_at: 5.hour.ago, status: :suspended) }
        let!(:tour_ongoing) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 6.hours.ago, status: :ongoing) }
        let!(:tour_closed) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 7.hours.ago, status: :closed) }
        let!(:tour_freezed) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 8.hours.ago, status: :freezed) }

        context "get default feeds" do
          before { get :index, token: user.token }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_open.id, entourage_closed.id, entourage_suspended_by_me.id, tour_ongoing.id, tour_closed.id, tour_freezed.id]) }
        end
      end

      context "PFP" do
        with_community :pfp
        let!(:tour) { nil }
        let!(:entourage) { nil }
        let!(:circle) { create :private_circle, :joined, user: user, join_request_role: :visitor, title: "Les amis de Jean" }
        let!(:neighborhood) { create :neighborhood, :joined, user: user, join_request_role: :member }
        let!(:conversation) { create :conversation, participants: [user] }
        before { get :index, token: user.token, status: "open" }
        it { expect(result["feeds"].map {|feed| feed["data"]["uuid"]}.sort).to eq([circle.uuid, neighborhood.uuid, conversation.uuid_v2].sort) }
      end
    end

    context "unread tab" do
      let(:user) { create :public_user }
      let(:action_creator) { create :public_user }
      let(:entourage) { create :entourage, user: action_creator, feed_updated_at: feed_updated_at }
      let(:join_status) { :accepted }
      let!(:join_request) { create :join_request, user: user, joinable: entourage, status: join_status, last_message_read: last_message_read }

      let(:feed_objects) do
        get :index, token: user.token, unread_only: true
        result["feeds"].map { |f| [f["type"], f["data"]["id"]]}
      end

      context "member of the group" do
        context "read" do
          let(:feed_updated_at) { 1.hour.ago }
          let(:last_message_read) { 1.minute.ago }

          it { expect(feed_objects).to eq [] }
        end

        context "unread" do
          let(:feed_updated_at) { 1.minute.ago }
          let(:last_message_read) { 1.hour.ago }

          it { expect(feed_objects).to eq [["Entourage", entourage.id]] }
        end
      end

      context "unread but pending" do
        let(:join_status) { :pending }
        let(:feed_updated_at) { 1.minute.ago }
        let(:last_message_read) { 1.hour.ago }

        it { expect(feed_objects).to eq [] }
      end

      context "read but user is creator and join request pending" do
        let(:action_creator) { user }
        let(:feed_updated_at) { 1.hour.ago }
        let(:last_message_read) { 1.minute.ago }
        let!(:pending_join_request) { create :join_request, joinable: entourage, status: :pending }

        it { expect(feed_objects).to eq [["Entourage", entourage.id]] }
      end
    end
  end
end
