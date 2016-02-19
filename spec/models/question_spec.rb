require 'rails_helper'

RSpec.describe Question, type: :model do
  it { should validate_presence_of :title }
  it { should validate_presence_of :answer_type }
  it { should validate_presence_of :answer_value }
  it { should validate_presence_of :organization_id }
end
