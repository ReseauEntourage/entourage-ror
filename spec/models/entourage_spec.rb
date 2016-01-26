require 'rails_helper'

RSpec.describe Entourage, type: :model do
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:type) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }
  it { should validate_presence_of(:number_of_people) }
  it { should belong_to(:user) }
end
