require 'rails_helper'

describe Preloaders::InappNotification do
  describe '.preload_records' do
    let(:user) { create :public_user }
    let(:outing) { create :outing }
    let(:neighborhood) { create :neighborhood }

    let!(:outing_notification) { create :inapp_notification, user: user, instance: :outing, instance_id: outing.id, context: :outing_on_update }
    let!(:neighborhood_notification) { create :inapp_notification, user: user, instance: :neighborhood, instance_id: neighborhood.id, context: :neighborhood_on_update }
    let!(:missing_notification) { create :inapp_notification, user: user, instance: :outing, instance_id: 0, context: :outing_on_update }

    it 'assigns the record of each notification, without query afterwards' do
      notifications = InappNotification.where(user: user).to_a
      Preloaders::InappNotification.preload_records(notifications)

      queries = []
      callback = lambda { |*, payload| queries << payload[:sql] }
      records = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        notifications.index_by(&:id).transform_values(&:record)
      end

      expect(records[outing_notification.id]).to eq(Outing.find(outing.id))
      expect(records[neighborhood_notification.id]).to eq(neighborhood)
      expect(records[missing_notification.id]).to be_nil
      expect(queries).to be_empty
    end

    it 'finds the same records as InappNotification#record' do
      notifications = InappNotification.where(user: user).to_a
      Preloaders::InappNotification.preload_records(notifications)

      expect(notifications.map(&:record)).to eq(InappNotification.where(user: user).map(&:record))
    end
  end
end
