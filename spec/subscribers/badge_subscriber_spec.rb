require 'rails_helper'

RSpec.describe BadgeSubscriber do
  let(:user) { create(:public_user, goal: 'ask_for_help') }

  before do
    allow(EventBus).to receive(:publish)
    allow(BadgeService).to receive(:check_bienvenue)
    allow(BadgeService).to receive(:check_premier_contact)
    allow(BadgeService).to receive(:check_moteur_rencontres)
    allow(BadgeService).to receive(:check_fidele_papotages)
    allow(BadgeService).to receive(:check_voix_presente)
  end

  describe '.on_join_request' do
    context 'with an accepted outing join request' do
      let(:outing) { create(:outing) }
      let(:join_request) { create(:join_request, user: user, joinable: outing, status: 'accepted') }

      it 'calls check_bienvenue with the user' do
        BadgeSubscriber.on_join_request(record: join_request)
        expect(BadgeService).to have_received(:check_bienvenue)
          .with(satisfy { |u| u.id == user.id })
      end

      it 'does not call check_fidele_papotages' do
        BadgeSubscriber.on_join_request(record: join_request)
        expect(BadgeService).not_to have_received(:check_fidele_papotages)
      end
    end

    context 'with an accepted papotage join request with participate_at' do
      let(:outing) { create(:outing, title: 'Papotage', online: true) }
      let(:join_request) do
        create(:join_request, user: user, joinable: outing, status: 'accepted', participate_at: Time.now)
      end

      it 'calls check_fidele_papotages with the user' do
        BadgeSubscriber.on_join_request(record: join_request)
        expect(BadgeService).to have_received(:check_fidele_papotages)
          .with(satisfy { |u| u.id == user.id })
      end
    end

    context 'with a pending join request' do
      let(:outing) { create(:outing) }
      let(:join_request) { create(:join_request, user: user, joinable: outing, status: 'pending') }

      it 'does nothing' do
        BadgeSubscriber.on_join_request(record: join_request)
        expect(BadgeService).not_to have_received(:check_bienvenue)
        expect(BadgeService).not_to have_received(:check_fidele_papotages)
      end
    end
  end

  describe '.on_chat_message' do
    context 'with a non-conversation message' do
      let(:message) { create(:chat_message, user: user) }

      it 'calls check_bienvenue' do
        BadgeSubscriber.on_chat_message(record: message)
        expect(BadgeService).to have_received(:check_bienvenue)
      end

      it 'does not call check_premier_contact' do
        BadgeSubscriber.on_chat_message(record: message)
        expect(BadgeService).not_to have_received(:check_premier_contact)
      end
    end

    context 'with a conversation message' do
      let(:other_user) { create(:public_user) }
      let(:conversation) { create(:conversation, participants: [user, other_user]) }
      let(:message) { create(:chat_message, messageable: conversation, user: user) }

      it 'calls check_premier_contact with the message' do
        BadgeSubscriber.on_chat_message(record: message)
        expect(BadgeService).to have_received(:check_premier_contact).with(message)
      end

      it 'does not call check_bienvenue' do
        BadgeSubscriber.on_chat_message(record: message)
        expect(BadgeService).not_to have_received(:check_bienvenue)
      end
    end
  end

  describe '.on_users_resource' do
    let(:resource) { create(:resource) }

    context 'when resource is watched' do
      let(:users_resource) { create(:users_resource, user: user, resource: resource, watched: true) }

      it 'calls check_bienvenue' do
        BadgeSubscriber.on_users_resource(record: users_resource)
        expect(BadgeService).to have_received(:check_bienvenue)
          .with(satisfy { |u| u.id == user.id })
      end
    end

    context 'when resource is not watched' do
      let(:users_resource) { create(:users_resource, user: user, resource: resource, watched: false) }

      it 'does not call check_bienvenue' do
        BadgeSubscriber.on_users_resource(record: users_resource)
        expect(BadgeService).not_to have_received(:check_bienvenue)
      end
    end
  end

  describe '.on_user_reaction' do
    let(:chat_message) { create(:chat_message) }
    let(:reaction) { create(:reaction) }
    let(:user_reaction) { create(:user_reaction, user: user, instance: chat_message, reaction: reaction) }

    it 'calls check_bienvenue' do
      BadgeSubscriber.on_user_reaction(record: user_reaction)
      expect(BadgeService).to have_received(:check_bienvenue)
        .with(satisfy { |u| u.id == user.id })
    end
  end

  describe '.on_user_profile_updated' do
    it 'calls check_bienvenue with the user' do
      BadgeSubscriber.on_user_profile_updated(record: user)
      expect(BadgeService).to have_received(:check_bienvenue)
        .with(satisfy { |u| u.id == user.id })
    end

    it 'is triggered by the user.profile_updated event' do
      BadgeSubscriber.register!
      allow(EventBus).to receive(:publish).and_call_original
      EventBus.publish("user.profile_updated", record: user)
      expect(BadgeService).to have_received(:check_bienvenue)
        .with(satisfy { |u| u.id == user.id })
    end
  end

  describe '.on_entourage' do
    context 'when entourage is an outing' do
      let(:outing) { create(:outing, user: user) }

      it 'calls check_moteur_rencontres' do
        BadgeSubscriber.on_entourage(record: outing)
        expect(BadgeService).to have_received(:check_moteur_rencontres)
          .with(satisfy { |u| u.id == user.id })
      end

      it 'is triggered by the outing.updated event' do
        BadgeSubscriber.register!
        allow(EventBus).to receive(:publish).and_call_original
        EventBus.publish("outing.updated", record: outing)
        expect(BadgeService).to have_received(:check_moteur_rencontres)
          .with(satisfy { |u| u.id == user.id })
      end
    end

    context 'when entourage is not an outing' do
      let(:entourage) { create(:entourage, user: user, group_type: 'action') }

      it 'does not call check_moteur_rencontres' do
        BadgeSubscriber.on_entourage(record: entourage)
        expect(BadgeService).not_to have_received(:check_moteur_rencontres)
      end
    end
  end
end
