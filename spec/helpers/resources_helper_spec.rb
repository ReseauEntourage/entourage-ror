require 'rails_helper'

RSpec.describe ResourcesHelper, type: :helper do
  describe '#views_for' do
    let(:resource) { create :resource }
    let(:other_resource) { create :resource, name: 'Autre ressource' }

    before do
      2.times { create :users_resource, resource: resource, watched: true }
      create :users_resource, resource: resource, watched: false
      create :users_resource, resource: resource, watched: true, user: create(:pro_user, admin: true)
      create :users_resource, resource: other_resource, watched: true
    end

    it 'counts the non admin users who watched the resource' do
      expect(helper.views_for(resource)).to eq(2)
    end

    it 'reads the grouped counts of Admin::ResourcesController#index' do
      assign(:views_by_resource_id, UsersResource.watched.joins(:user)
        .where(resource_id: [resource.id, other_resource.id, create(:resource, name: 'Sans vue').id], users: { admin: false })
        .group(:resource_id)
        .count)

      expect([helper.views_for(resource), helper.views_for(other_resource)]).to eq([2, 1])
      expect(helper.views_for(Resource.find_by(name: 'Sans vue'))).to eq(0)
    end
  end
end
