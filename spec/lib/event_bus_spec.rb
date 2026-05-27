require 'rails_helper'

RSpec.describe EventBus do
  before do
    # Reset subscribers between tests
    EventBus.instance_variable_set(:@subscribers, Hash.new { |h, k| h[k] = [] })
  end

  describe '.subscribe' do
    it 'registers a handler for an event' do
      called = false
      EventBus.subscribe('test.event', ->(_) { called = true })
      EventBus.publish('test.event', {})
      expect(called).to be true
    end

    it 'allows multiple handlers for the same event' do
      calls = []
      EventBus.subscribe('test.event', ->(_) { calls << 1 })
      EventBus.subscribe('test.event', ->(_) { calls << 2 })
      EventBus.publish('test.event', {})
      expect(calls).to eq([1, 2])
    end
  end

  describe '.publish' do
    it 'passes the payload to the handler' do
      received_payload = nil
      EventBus.subscribe('test.event', ->(payload) { received_payload = payload })
      EventBus.publish('test.event', { foo: 'bar' })
      expect(received_payload).to eq({ foo: 'bar' })
    end

    it 'does nothing when no handlers are registered' do
      expect { EventBus.publish('unregistered.event', {}) }.not_to raise_error
    end

    it 'does not call handlers for other events' do
      called = false
      EventBus.subscribe('other.event', ->(_) { called = true })
      EventBus.publish('test.event', {})
      expect(called).to be false
    end
  end
end
