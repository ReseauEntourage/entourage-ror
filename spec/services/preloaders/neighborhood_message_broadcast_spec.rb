require 'rails_helper'

describe Preloaders::NeighborhoodMessageBroadcast do
  describe '.preload_recipients' do
    let!(:paris_ville) { create :neighborhood, name: 'Paris 11', postal_code: '75011', zone: :ville, number_of_people: 10 }
    let!(:paris_departement) { create :neighborhood, name: 'Paris', postal_code: '75000', zone: :departement, number_of_people: 20 }
    let!(:paris_no_zone) { create :neighborhood, name: 'Paris 12', postal_code: '75012', zone: nil, number_of_people: 30 }
    let!(:lyon) { create :neighborhood, name: 'Lyon', postal_code: '69001', zone: :ville, number_of_people: 40 }
    let!(:inactive) { create :neighborhood, name: 'Paris inactif', postal_code: '75013', zone: :ville, status: :deleted }

    def broadcast_with(departements: nil, area_type: nil, conversation_ids: nil)
      broadcast = create :neighborhood_message_broadcast, area_type: area_type
      broadcast.conversation_ids = conversation_ids if conversation_ids
      broadcast.specific_filters = { 'departements' => departements } if departements
      broadcast.save!
      broadcast
    end

    let!(:broadcasts) do
      [
        broadcast_with(departements: ['75']),
        broadcast_with(departements: ['75', '69'], area_type: 'ville'),
        broadcast_with(departements: ['75'], area_type: 'departement'),
        broadcast_with(departements: ['75'], area_type: 'no_zone'),
        broadcast_with(departements: ['13']),
        broadcast_with(conversation_ids: [lyon.id, paris_ville.id].map(&:to_s)),
      ]
    end

    def summary(broadcast)
      [broadcast.recipient_ids.sort, broadcast.recipients_number_of_people, broadcast.recipient_names(limit: 3).sort]
    end

    it 'preloads the same recipients as the per broadcast queries, in two queries' do
      preloaded = NeighborhoodMessageBroadcast.where(id: broadcasts.map(&:id)).order(:id).to_a

      queries = []
      callback = lambda { |*, payload| queries << payload[:sql] unless payload[:name] == 'SCHEMA' }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { Preloaders::NeighborhoodMessageBroadcast.preload_recipients(preloaded) }

      expected = NeighborhoodMessageBroadcast.where(id: broadcasts.map(&:id)).order(:id).map { |broadcast| summary(broadcast) }

      expect(preloaded.map { |broadcast| summary(broadcast) }).to eq(expected)
      expect(expected.map(&:first)).to eq([
        [paris_ville.id, paris_departement.id, paris_no_zone.id].sort,
        [paris_ville.id, lyon.id].sort,
        [paris_departement.id],
        [paris_no_zone.id],
        [],
        [paris_ville.id, lyon.id].sort,
      ])
      expect(queries.size).to eq(2)
    end
  end
end
