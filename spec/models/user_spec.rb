require 'rails_helper'

describe User, :type => :model do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should define_enum_for(:device_type) }
end