require 'rails_helper'

describe Preloaders::UserSmalltalk do
  describe '.preload_interests' do
    let(:sport) { Tag.find_or_create_by!(name: 'sport') }
    let(:cuisine) { Tag.find_or_create_by!(name: 'cuisine') }

    let!(:user_smalltalk) { create :user_smalltalk, user_interest_ids: [sport.id, cuisine.id] }
    let!(:without_interest) { create :user_smalltalk, user_interest_ids: [] }

    it 'serves the same interest names without further query' do
      user_smalltalks = UserSmalltalk.where(id: [user_smalltalk.id, without_interest.id]).order(:id).to_a
      Preloaders::UserSmalltalk.preload_interests(user_smalltalks)

      queries = []
      callback = lambda { |*, payload| queries << payload[:sql] }
      names = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { user_smalltalks.map(&:interest_names) }

      expect(names).to eq([user_smalltalk.reload.interest_names, []])
      expect(names.first).to eq(['cuisine', 'sport'])
      expect(queries).to be_empty
    end
  end
end
