FactoryBot.define do
  factory :image_resize_action do
    bucket { :entourage_bucket }
    path { 'destination/path' }
    destination_path { 'destination/medium/path' }
    destination_size { :medium }
    status { :OK }
  end
end
