require 'rails_helper'

RSpec.describe Organization, type: :model do
  it { should validate_presence_of :name }
  it { should validate_presence_of :description }
  it { should validate_presence_of :phone }
  it { should validate_presence_of :address }
  it { should validate_uniqueness_of :name }
  it { should have_many :users }
end
