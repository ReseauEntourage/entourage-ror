require 'rails_helper'
include CommunityHelper

RSpec.describe EntourageImage, type: :model do
  describe "from_absolute_to_relative_url" do
    subject { EntourageImage.from_absolute_to_relative_url(url) }

    context 'no url' do
      let(:url) { nil }
      it { expect(subject).to eq(nil) }
    end

    context 'empty url' do
      let(:url) { "" }
      it { expect(subject).to eq(nil) }
    end

    context 'without parameters' do
      let(:url) { "foo" }
      it { expect(subject).to eq("entourage_images/images/foo") }
    end

    context 'with parameters' do
      let(:url) { "foo?bar=1&baz=test" }
      it { expect(subject).to eq("entourage_images/images/foo") }
    end
  end
end
