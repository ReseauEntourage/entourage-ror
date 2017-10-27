require 'rails_helper'

RSpec.describe Organization, type: :model do
  it { should validate_presence_of :name }
  it { should validate_presence_of :address }
  it { should validate_uniqueness_of :name }
  it { should have_many :users }
  it { should have_many :questions }

  it "should count encounters" do
    organization = FactoryGirl.create(:organization)
    user         = FactoryGirl.create(:pro_user, organization: organization)
    tour         = FactoryGirl.create(:tour, user: user)
    FactoryGirl.create_list(:encounter, 4, tour: tour)

    expect(organization.meetings_count).to eq(4)
  end

  it "should count tours" do
    organization  = FactoryGirl.create(:organization)
    user          = FactoryGirl.create(:pro_user, organization_id: organization.id)
    FactoryGirl.create_list(:tour, 3, user: user)

    expect(organization.tours_count).to eq(3)
  end

  it "should count last month active members" do
    organization  = FactoryGirl.create(:organization)
    FactoryGirl.create_list(:user, 6, organization: organization, last_sign_in_at: Time.current - 5.days)

    expect(organization.active_members_last_month).to eq(6)
  end

  it "should retrieve last tour date" do
    organization = FactoryGirl.create(:organization)
    user         = FactoryGirl.create(:pro_user, organization_id: organization.id)
    FactoryGirl.create_list(:tour, 6, user: user)

    expect(organization.last_tour_date).to eq(Tour.last.updated_at.strftime('%d/%m/%Y'))
  end
end
