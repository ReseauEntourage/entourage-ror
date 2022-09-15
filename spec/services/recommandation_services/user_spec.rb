require 'rails_helper'

describe RecommandationServices::Finder do
  let(:user) { FactoryBot.create(:pro_user) }
  let(:subject) { RecommandationServices::Finder.new(user: user) }

  describe 'find' do
  end
end
