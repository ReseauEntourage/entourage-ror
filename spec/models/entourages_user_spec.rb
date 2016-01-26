require 'rails_helper'

RSpec.describe EntouragesUser, type: :model do
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :entourage_id }
  it { should belong_to :user }
  it { should belong_to :entourage }
end
