require 'rails_helper'

RSpec.describe UsersAppetence, type: :model do
  it { expect(FactoryGirl.build(:users_appetence).save).to be true }
  it { should validate_presence_of :appetence_social }
  it { should validate_presence_of :appetence_mat_help }
  it { should validate_presence_of :appetence_non_mat_help }
  it { should validate_presence_of :avg_dist }
end
