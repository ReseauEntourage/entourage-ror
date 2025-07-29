require 'rails_helper'

describe Storage::Bucket do

  let(:bucket) { Storage::Bucket.new('foo') }

  describe 'url_for' do
    it { expect(bucket.url_for(key: 'foo')).to match(/https:\/\/foo.s3.eu-west-1.amazonaws.com\/foo/) }
    it { expect { bucket.url_for(key: '') }.to raise_error(ArgumentError) }
  end
end
