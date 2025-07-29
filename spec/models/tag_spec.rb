require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'interest_list' do
    let(:subject) { Tag.interest_list }

    it { expect(subject).to include('sport') }
  end

  describe 'interests' do
    let(:subject) { Tag.interests }

    it { expect(subject).to have_key(:sport) }
    it { expect(subject[:sport]).to eq('Sport') }
  end
end
