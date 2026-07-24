require 'rails_helper'

RSpec.describe RouteCompletionJob do
  let(:user) { create(:public_user) }

  subject { described_class.new.perform(user.id, 'neighborhoods', 'index', {}) }

  it 'runs a RouteCompletionService for the user' do
    expect(RouteCompletionService).to receive(:new).with(
      user: user,
      controller_name: 'neighborhoods',
      action_name: 'index',
      params: instance_of(ActionController::Parameters)
    ).and_call_original

    subject
  end

  context 'when the user no longer exists' do
    subject { described_class.new.perform(0, 'neighborhoods', 'index', {}) }

    it 'does nothing' do
      expect(RouteCompletionService).not_to receive(:new)

      subject
    end
  end
end
