require 'rails_helper'

RSpec.describe Tour, :type => :model do
  
  describe 'tour validation' do
    
    subject { Tour.new }
    
    it { should validate_inclusion_of(:tour_type).in_array(%w(health friendly social food other)) }
    it { should define_enum_for(:vehicle_type) }
    it { should define_enum_for(:status) }
    it { should validate_presence_of(:tour_type) }
    it { should validate_presence_of(:vehicle_type) }
    it { should validate_presence_of(:status) }

  end
  
end
