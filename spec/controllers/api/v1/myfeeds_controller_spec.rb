require 'rails_helper'

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
        it { expect(result).to eq({"feeds"=>[]}) }
      end

      context "get my entourages" do
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago) }
        let!(:entourage_i_joined) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 2.hour.ago) }
        before { get :index, token: user.token }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, entourage_i_joined.id]) }
      end

      context "last_message" do
        let!(:entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, created_at: 1.hour.ago) }
        let!(:tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, created_at: 1.hour.ago) }

        context "has messages" do
          let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("25/01/2000"), updated_at: DateTime.parse("25/01/2000"), content: "foo") }
          let!(:chat_message2) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("24/01/2000"), updated_at: DateTime.parse("24/01/2000"), content: "bar") }
          let!(:chat_message3) { FactoryGirl.create(:chat_message, messageable: tour, created_at: DateTime.parse("11/01/2000"), updated_at: DateTime.parse("11/01/2000"), content: "tour_foo") }
          before { get :index, token: user.token }
          it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"foo", "author"=>{"first_name"=>"John", "last_name"=>"Doe"}}, {"text"=>"tour_foo", "author"=>{"first_name"=>"John", "last_name"=>"Doe"}}]) }
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
          it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"1 nouvelle demande pour rejoindre votre entourage", "author"=>nil}, nil]) }
        end

        context "has pending join_request and messages" do
          context "messages more recent that join requests" do
            let!(:join_request) do
              entourage.join_requests.last.update(message: "foo_bar", status: "pending", created_at: DateTime.parse("10/01/2015"), updated_at: DateTime.parse("10/01/2015"))
            end
            let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("10/01/2016"), updated_at: DateTime.parse("10/01/2016"), content: "foo") }
            before { get :index, token: user.token }
            it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"foo", "author"=>{"first_name"=>"John", "last_name"=>"Doe"}}, nil]) }
          end

          context "join requests more recent that messages" do
            let!(:join_request) do
              entourage.join_requests.last.update(message: "foo_bar", status: "pending", created_at: DateTime.parse("10/01/2016"), updated_at: DateTime.parse("10/01/2016"))
            end
            let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("10/01/2015"), updated_at: DateTime.parse("10/01/2015"), content: "foo") }
            before { get :index, token: user.token }
            it { expect(result["feeds"].map {|feed| feed["data"]["last_message"]} ).to eq([{"text"=>"1 nouvelle demande pour rejoindre votre entourage", "author"=>nil}, nil]) }
          end
        end
      end

      context "filter by status" do
        let!(:entourage_open) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, status: :open) }
        let!(:entourage_closed) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 2.hour.ago, status: :closed) }
        let!(:tour_ongoing) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 3.hours.ago, status: :ongoing) }
        let!(:tour_closed) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 4.hours.ago, status: :closed) }
        let!(:tour_freezed) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 5.hours.ago, status: :freezed) }

        context "get active feeds" do
          before { get :index, token: user.token, status: "active" }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_open.id, tour_ongoing.id, tour_closed.id]) }
        end

        context "get active feeds" do
          before { get :index, token: user.token, status: "closed" }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_closed.id, tour_freezed.id]) }
        end
      end

      context "filter created_by_me" do
        let!(:my_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, status: :open) }
        let!(:other_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 1.hour.ago, status: :open) }
        let!(:my_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, updated_at: 3.hours.ago, status: :ongoing) }
        let!(:other_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 3.hours.ago, status: :ongoing) }
        before { get :index, token: user.token, created_by_me: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_entourage.id, my_tour.id]) }
      end

      context "filter accepted_invitation" do
        let!(:invited_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, status: :open) }
        let!(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, :accepted, invitee: user, invitable: invited_entourage) }
        let!(:other_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 1.hour.ago, status: :open) }
        let!(:other_entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user, invitable: other_entourage) }
        let!(:invited_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, updated_at: 3.hours.ago, status: :ongoing) }
        let!(:tour_invitation) { FactoryGirl.create(:entourage_invitation, :accepted, invitee: user, invitable: invited_tour) }
        let!(:other_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 3.hours.ago, status: :ongoing) }
        before { get :index, token: user.token, accepted_invitation: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([invited_entourage.id, invited_tour.id]) }
      end

      context "filter created_by_me OR accepted_invitation" do
        let!(:my_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 30.minutes.ago, status: :open) }
        let!(:my_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, updated_at: 90.minutes.ago, status: :ongoing) }
        let!(:other_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 91.minutes.ago, status: :ongoing) }
        let!(:invited_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 31.minutes.ago, status: :open) }
        let!(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, :accepted, invitee: user, invitable: invited_entourage) }
        let!(:other_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 32.minutes.ago, status: :open) }
        let!(:other_entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user, invitable: other_entourage) }
        let!(:invited_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, updated_at: 92.minutes.ago, status: :ongoing) }
        let!(:tour_invitation) { FactoryGirl.create(:entourage_invitation, :accepted, invitee: user, invitable: invited_tour) }
        let!(:other_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 93.minutes.ago, status: :ongoing) }
        before { get :index, token: user.token, created_by_me: "true", accepted_invitation: "true"  }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_entourage.id, invited_entourage.id, my_tour.id, invited_tour.id]) }
      end
    end
  end
end