require 'spec_helper'

describe User do

  describe 'user creation' do
    Factory.create(:user).should be_valid
  end

end
