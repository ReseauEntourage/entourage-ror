require 'rails_helper'

RSpec.describe ChatMessage, type: :model do
  it { expect(FactoryGirl.build(:chat_message).save).to be true }
  it { should belong_to :messageable }
  it { should belong_to :user }
  it { should validate_presence_of :messageable_id }
  it { should validate_presence_of :messageable_type }
  it { should validate_presence_of :content }
  it { should validate_presence_of :user_id }
end
