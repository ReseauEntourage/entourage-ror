require 'rails_helper'

RSpec.describe PushNotificationTrigger, type: :service do
  describe '#notify_cable' do
    let(:user) { create(:public_user) }
    let(:user_badge) { create(:user_badge, user: user, badge_tag: 'bienvenue') }

    subject(:trigger) { described_class.new(user_badge, :create, {}) }

    # Eagerly create trigger (and its dependencies) so observer-triggered broadcasts
    # happen before the expect {} block and are not counted by have_broadcasted_to
    before { trigger }

    def call_notify_cable(instance:, users:)
      trigger.send(:notify_cable,
        sender_id: nil,
        referent: instance,
        instance: instance,
        users: users
      )
    end

    context "avec un UserBadge" do
      it "diffuse sur le canal de l'utilisateur" do
        expect {
          call_notify_cable(instance: user_badge, users: [user])
        }.to have_broadcasted_to("notifications_#{user.id}")
      end

      it "inclut le type, l'id, le user_id et les données du badge" do
        expect {
          call_notify_cable(instance: user_badge, users: [user])
        }.to have_broadcasted_to("notifications_#{user.id}").with(
          type: "user_badge",
          id: user_badge.id,
          user_id: user.id,
          data: {
            name: user_badge.badge_tag,
            awarded_at: user_badge.awarded_at.as_json,
            metadata: user_badge.metadata
          }
        )
      end

      context "avec plusieurs utilisateurs" do
        let(:other_user) { create(:public_user) }

        it "diffuse à chaque utilisateur" do
          expect {
            call_notify_cable(instance: user_badge, users: [user, other_user])
          }.to have_broadcasted_to("notifications_#{user.id}")
            .and have_broadcasted_to("notifications_#{other_user.id}")
        end
      end

      context "avec un utilisateur nil dans la liste" do
        it "ne lève pas d'erreur et ignore l'utilisateur nil" do
          expect {
            call_notify_cable(instance: user_badge, users: [nil, user])
          }.not_to raise_error
        end

        it "diffuse quand même aux utilisateurs valides" do
          expect {
            call_notify_cable(instance: user_badge, users: [nil, user])
          }.to have_broadcasted_to("notifications_#{user.id}")
        end
      end
    end

    context "avec une instance autre que UserBadge" do
      let(:other_instance) { create(:neighborhood) }

      # Eagerly create to avoid lazy evaluation inside expect {} block
      before { other_instance }

      it "ne diffuse rien" do
        expect {
          call_notify_cable(instance: other_instance, users: [user])
        }.not_to have_broadcasted_to("notifications_#{user.id}")
      end
    end
  end
end
