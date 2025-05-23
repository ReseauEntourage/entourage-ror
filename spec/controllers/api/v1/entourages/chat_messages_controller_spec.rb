require 'rails_helper'
include CommunityHelper

describe Api::V1::Entourages::ChatMessagesController do

  let(:entourage) { FactoryBot.create(:entourage) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index, params: { entourage_id: entourage.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "onboarding entourage" do
      let(:moderator) { FactoryBot.create(:pro_user, admin: true, phone: '+33768037348') }
      let(:nantes) { FactoryBot.create(:entourage, id: 3347) }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: nantes, user: moderator, status: "accepted") }

      before { get :index, params: { entourage_id: nantes.to_param, token: moderator.token } }
      it { expect(response.status).to eq(200) }
    end

    context "signed in" do
      let(:user) { FactoryBot.create(:pro_user) }

      context "i belong to the entourage" do
        let!(:chat_message1) { FactoryBot.create(:chat_message, messageable: entourage, created_at: DateTime.parse("10/01/2000"), updated_at: DateTime.parse("10/01/2000")) }
        let!(:chat_message2) { FactoryBot.create(:chat_message, messageable: entourage, created_at: DateTime.parse("09/01/2000"), updated_at: DateTime.parse("09/01/2000")) }
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        before { get :index, params: { entourage_id: entourage.to_param, token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({
          "chat_messages"=> [{
            "id" => chat_message1.id,
            "uuid_v2" => chat_message1.uuid_v2,
            "message_type" => "text",
            "content" => "MyText",
            "content_html" => "MyText",
            "content_translations" => {
              "translation" => "MyText",
              "original" => "MyText",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "content_translations_html" => {
              "translation" => "MyText",
              "original" => "MyText",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "user" => {
              "id" => chat_message1.user_id,
              "avatar_url" => nil,
              "display_name" => "John D.",
              "partner" => nil,
              "partner_role_title" => nil,
              "roles" => []
            },
            "created_at" => chat_message1.created_at.iso8601(3),
            "status" => "active"
          }, {
            "id" => chat_message2.id,
            "uuid_v2" => chat_message2.uuid_v2,
            "message_type" => "text",
            "content" => "MyText",
            "content_html" => "MyText",
            "content_translations" => {
              "translation" => "MyText",
              "original" => "MyText",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "content_translations_html" => {
              "translation" => "MyText",
              "original" => "MyText",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "user" => {
              "id" => chat_message2.user_id,
              "avatar_url" => nil,
              "display_name" => "John D.",
              "partner" => nil,
              "partner_role_title" => nil,
              "roles" => []
            },
            "created_at" => chat_message2.created_at.iso8601(3),
            "status" => "active"
          }]
        }) }

        it { expect(join_request.reload.last_message_read).to eq(chat_message1.created_at)}
      end

      context "i request older messages" do
        let!(:chat_messages) { FactoryBot.create_list(:chat_message, 2, messageable: entourage, created_at: DateTime.parse("10/01/2016")) }
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted", last_message_read: DateTime.parse("20/01/2016")) }
        before { get :index, params: { entourage_id: entourage.to_param, token: user.token } }
        it { expect(join_request.reload.last_message_read).to eq(DateTime.parse("20/01/2016"))}
      end

      context "i don't belong to the entourage" do
        before { get :index, params: { entourage_id: entourage.to_param, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "i am still in pending status" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "pending") }
        before { get :index, params: { entourage_id: entourage.to_param, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "i am rejected from the entourage" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "rejected") }
        before { get :index, params: { entourage_id: entourage.to_param, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "i quit the entourage" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "cancelled") }
        before { get :index, params: { entourage_id: entourage.to_param, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "pagination" do
        let!(:chat_message1) { FactoryBot.create(:chat_message, messageable: entourage, updated_at: DateTime.parse("11/01/2016")) }
        let!(:chat_message2) { FactoryBot.create(:chat_message, messageable: entourage, updated_at: DateTime.parse("09/01/2016")) }
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        before { get :index, params: { entourage_id: entourage.to_param, token: user.token, before: "10/01/2016" } }
        it { expect(JSON.parse(response.body)).to eq({
          "chat_messages"=>[{
            "id" => chat_message2.id,
            "uuid_v2" => chat_message2.uuid_v2,
            "message_type" => "text",
            "content" => "MyText",
            "content_html" => "MyText",
            "content_translations" => {
              "translation" => "MyText",
              "original" => "MyText",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "content_translations_html" => {
              "translation" => "MyText",
              "original" => "MyText",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "user" => {
              "id" => chat_message2.user.id,
              "avatar_url" => nil,
              "display_name" => "John D.",
              "partner" => nil,
              "partner_role_title" => nil,
              "roles" => []
            },
            "created_at" => chat_message2.created_at.iso8601(3),
            "status" => "active"
          }]
        }) }
      end

      context "user with partner" do
        let(:partner_user) { FactoryBot.create(:partner_user) }
        let!(:chat_message) { FactoryBot.create(:chat_message, messageable: entourage, user: partner_user) }
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: partner_user, status: "accepted") }
        before { get :index, params: { entourage_id: entourage.to_param, token: partner_user.token } }
        it { expect(JSON.parse(response.body)).to eq({
          "chat_messages" => [{
            "id" => chat_message.id,
            "uuid_v2" => chat_message.uuid_v2,
            "message_type" => "text",
            "content" => "MyText",
            "content_html" => "MyText",
            "content_translations" => {
              "translation" => "MyText",
              "original" => "MyText",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "content_translations_html" => {
              "translation" => "MyText",
              "original" => "MyText",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "user" => {
              "id" => chat_message.user_id,
              "avatar_url" => nil,
              "display_name" => "John D.",
              "partner" => {
                "id" => partner_user.partner_id,
                "name" => partner_user.partner.name,
                "large_logo_url" => partner_user.partner.large_logo_url,
                "small_logo_url" => partner_user.partner.small_logo_url,
                "default" => true,
              },
              "partner_role_title" => nil,
              "roles" => ["Association"]
            },
            "created_at" => chat_message.created_at.iso8601(3),
            "status" => "active"
          }]
        }) }
      end

      context "from a null conversations by list uuid" do
        with_community :pfp
        let!(:entourage) { nil }
        let(:other_user) { create :public_user, first_name: "Buzz", last_name: "Lightyear" }
        before { get :index, params: { entourage_id: "1_list_#{user.id}-#{other_user.id}", token: user.token } }
        it { expect(JSON.parse(response.body)).to eq("chat_messages"=>[]) }
      end
    end
  end

  describe 'POST create' do
    let(:token) { user.token }
    let(:content) { "foobar" }
    let(:message_type) { "text" }

    let(:request) { post :create, params: { entourage_id: entourage.to_param, chat_message: { content: content, message_type: message_type }, token: token } }

    context "not signed in" do
      let(:token) { nil }

      before { request }

      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context "signed in" do
      let!(:ios_app) { FactoryBot.create(:ios_app, name: 'entourage') }
      let!(:android_app) { FactoryBot.create(:android_app, name: 'entourage') }
      let(:user) { FactoryBot.create(:pro_user) }

      context "valid params" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        let!(:join_request2) { FactoryBot.create(:join_request, joinable: entourage, status: "accepted") }

        before { request }

        it { expect(response.status).to eq(201) }
        it { expect(ChatMessage.count).to eq(1) }
        it { expect(JSON.parse(response.body)).to eq({
          "chat_message" => {
            "id" => ChatMessage.first.id,
            "uuid_v2" => ChatMessage.first.uuid_v2,
            "message_type" => "text",
            "content" => "foobar",
            "content_html" => "foobar",
            "content_translations" => {
              "translation" => "foobar",
              "original" => "foobar",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "content_translations_html" => {
              "translation" => "foobar",
              "original" => "foobar",
              "from_lang" => "fr",
              "to_lang" => "fr",
            },
            "user" => {
              "id" => user.id,
              "avatar_url" => nil,
              "display_name" => "John D.",
              "partner" => nil,
              "partner_role_title" => nil,
              "roles" => []
            },
            "created_at" => ChatMessage.first.created_at.iso8601(3),
            "status" => "active"
          }
        }) }
      end

      describe "send push notif" do
        it "sends notif to everyone accepted except message sender" do
          join_request = FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted")
          join_request2 = FactoryBot.create(:join_request, joinable: entourage, status: "accepted")

          FactoryBot.create(:join_request, joinable: entourage, status: "pending")

          expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
            nil,
            PushNotificationTrigger::I18nStruct.new(text: 'John D. - Foobar'),
            PushNotificationTrigger::I18nStruct.new(instance: kind_of(Entourage), field: :title),
            [join_request2.user],
            "solicitation",
            entourage.id,
            {
              tracking: :public_chat_message_on_create,
              joinable_id: entourage.id,
              joinable_type: "Entourage",
              group_type: 'action',
              type: "NEW_CHAT_MESSAGE",
              instance: "conversation",
              instance_id: entourage.id
            }
          )

          request
        end
      end

      context "invalid params" do
        let(:content) { nil }
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted") }

        before { request }

        it { expect(response.status).to eq(400) }
        it { expect(ChatMessage.count).to eq(0) }
      end

      context "post in a entourage i don't belong to" do
        before { request }

        it { expect(response.status).to eq(401) }
      end

      context "post in a entourage i am still in pending status" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "pending") }

        before { request }

        it { expect(response.status).to eq(401) }
      end

      context "post in a entourage i am rejected from" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "rejected") }

        before { request }

        it { expect(response.status).to eq(401) }
      end

      context "post in a entourage i have quit" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "cancelled") }

        before { request }

        it { expect(response.status).to eq(401) }
      end

      context "invalid message type" do
        let(:message_type) { "status_update" }
        let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted") }

        before { request }

        it { expect(response.status).to eq(400) }
        it { expect(JSON.parse(response.body)).to eq("message"=>"Could not create chat message",
                                                     "reasons"=>["Message type n'est pas inclus(e) dans la liste"]) }
      end

      describe "to a null conversations by list uuid" do
        let!(:entourage) { nil }
        let(:other_user) { create :public_user, first_name: "Buzz", last_name: "Lightyear" }
        let(:join_requests) { Entourage.last.join_requests.map(&:attributes) }

        let(:request) { post :create, params: { entourage_id: "1_list_#{user.id}-#{other_user.id}", chat_message: {content: content}, token: user.token } }

        context "user has been blocked" do
          let(:content) { "foobar" }
          let!(:user_blocked_user_1) { FactoryBot.create(:user_blocked_user, user: user, blocked_user: other_user) }

          before { request }

          it { expect(response.status).to eq(400) }
          it { expect(ChatMessage.count).to eq(0) }
        end

        context "other_user has been blocked" do
          let(:content) { "foobar" }
          let!(:user_blocked_user_2) { FactoryBot.create(:user_blocked_user, user: other_user, blocked_user: user) }

          before { request }

          it { expect(response.status).to eq(400) }
          it { expect(ChatMessage.count).to eq(0) }
        end

        context "no user has been blocked" do
          let(:content) { "foobar" }

          before { request }

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
        end

        context "valid params" do
          let(:content) { "foobar" }

          before { request }

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(JSON.parse(response.body)).to eq({
            "chat_message" => {
              "id" => ChatMessage.first.id,
              "uuid_v2" => ChatMessage.first.uuid_v2,
              "message_type" => "text",
              "content" => "foobar",
              "content_html" => "foobar",
              "content_translations" => {
                "translation" => "foobar",
                "original" => "foobar",
                "from_lang" => "fr",
                "to_lang" => "fr",
              },
              "content_translations_html" => {
                "translation" => "foobar",
                "original" => "foobar",
                "from_lang" => "fr",
                "to_lang" => "fr",
              },
              "user" => {
                "id" => user.id,
                "avatar_url" => nil,
                "display_name" => "John D.",
                "partner" => nil,
                "partner_role_title" => nil,
                "roles" => []
              },
              "created_at" => ChatMessage.first.created_at.iso8601(3),
              "status" => "active"
            }
          }) }
          it { expect(Entourage.last.attributes).to include(
            "user_id" => user.id,
            "number_of_people" => 2,
            "community" => 'entourage',
            "group_type" => "conversation"
          ) }
          it { expect(Entourage.last.attributes['uuid_v2']).to start_with '1_hash_' }
          it { expect(join_requests.map { |r| r['user_id'] }.sort).to eq([user.id, other_user.id]) }
          it { expect(join_requests.map { |r| r.slice('status', 'role') }.uniq).to eq(["status"=>"accepted", "role"=>"participant"]) }
          it { expect(join_requests.find {|r| r['user_id'] == other_user.id }['report_prompt_status']).to eq 'display' }
        end

        context "invalid params" do
          let(:content) { nil }

          before { request }

          it { expect(response.status).to eq(400) }
          it { expect(ChatMessage.count).to eq(0) }
          it { expect(Entourage.count).to eq(0) }
          it { expect(JoinRequest.count).to eq(0) }
        end
      end

      context "share" do
        let(:user) { create :public_user }
        let(:conversation) { create :conversation, participants: [user] }

        before { post :create, params: { entourage_id: conversation.to_param, chat_message: payload, token: user.token } }

        context "entourage" do
          let(:entourage) { create :entourage }
          let(:payload) do
            {
              message_type: 'share',
              metadata: {
                type: 'entourage',
                uuid: entourage.uuid_v2
              }
            }
          end

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(JSON.parse(response.body)).to eq({
            "chat_message" => {
              "id" => ChatMessage.last.id,
              "uuid_v2" => ChatMessage.last.uuid_v2,
              "content" => "#{entourage.title}\n#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
              "content_html" => "#{entourage.title}\n#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
              "content_translations" => {
                "translation" => "#{entourage.title}\n#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
                "original" => "#{entourage.title}\n#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
                "from_lang" => "fr",
                "to_lang" => "fr",
              },
              "content_translations_html" => {
                "translation" => "#{entourage.title}\n#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
                "original" => "#{entourage.title}\n#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
                "from_lang" => "fr",
                "to_lang" => "fr",
              },
              "user" => {
                "id" => user.id,
                "avatar_url" => nil,
                "display_name" => "John D.",
                "partner" => nil,
                "partner_role_title" => nil,
                "roles" => []
              },
              "created_at" => ChatMessage.last.created_at.iso8601(3),
              "status" => "active",
              "message_type" => "share",
              "metadata" => {
                "type" => "entourage",
                "uuid" => entourage.uuid_v2
              }
            }
          })}
        end

        context "poi" do
          let(:poi) { create :poi }
          let(:payload) do
            {
              message_type: 'share',
              metadata: {
                type: 'poi',
                uuid: poi.id
              }
            }
          end

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(JSON.parse(response.body)).to eq({
            "chat_message" => {
              "id" => ChatMessage.last.id,
              "uuid_v2" => ChatMessage.last.uuid_v2,
              "content" => "Dede\nAu 50 75008 Paris",
              "content_html" => "Dede\nAu 50 75008 Paris",
              "content_translations" => {
                "translation" => "Dede\nAu 50 75008 Paris",
                "original" => "Dede\nAu 50 75008 Paris",
                "from_lang" => "fr",
                "to_lang" => "fr",
              },
              "content_translations_html" => {
                "translation" => "Dede\nAu 50 75008 Paris",
                "original" => "Dede\nAu 50 75008 Paris",
                "from_lang" => "fr",
                "to_lang" => "fr",
              },
              "user" => {
                "id" => user.id,
                "avatar_url" => nil,
                "display_name" => "John D.",
                "partner" => nil,
                "partner_role_title" => nil,
                "roles" => []
              },
              "created_at" => ChatMessage.last.created_at.iso8601(3),
              "status" => "active",
              "message_type" => "share",
              "metadata" => {
                "type" => "poi",
                "uuid" => poi.id.to_s
              }
            }
          })}
        end
      end
    end
  end
end
