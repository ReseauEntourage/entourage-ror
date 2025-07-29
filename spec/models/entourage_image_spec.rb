require 'rails_helper'
include CommunityHelper

RSpec.describe EntourageImage, type: :model do
  describe 'size medium' do
    let(:image_resize_action) { create :image_resize_action, destination_path: 'bar' }
    let(:entourage_image) { create :entourage_image, landscape_url: 'foo', landscape_url_medium: image_resize_action }

    subject { entourage_image.landscape_url_medium_or_default }

    context 'with image_resize_action' do
      it { expect(subject).to eq('bar') }
    end

    context 'without image_resize_action' do
      let(:image_resize_action) { nil }

      it { expect(subject).to eq('foo') }
    end
  end

  describe 'from_absolute_to_relative_url' do
    subject { EntourageImage.from_absolute_to_relative_url(url) }

    context 'no url' do
      let(:url) { nil }
      it { expect(subject).to eq(nil) }
    end

    context 'empty url' do
      let(:url) { '' }
      it { expect(subject).to eq(nil) }
    end

    context 'without parameters' do
      let(:url) { 'foo' }
      it { expect(subject).to eq('entourage_images/images/foo') }
    end

    context 'with parameters' do
      let(:url) { 'foo?bar=1&baz=test' }
      it { expect(subject).to eq('entourage_images/images/foo') }
    end
  end
end
require 'rails_helper'
