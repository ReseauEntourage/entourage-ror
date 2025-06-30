FactoryBot.define do
  factory :meeting do
    title { "Test Meeting" }
    participant_emails { ["test@example.com"] }
    start_time { 1.week.from_now }
    end_time { 1.week.from_now + 1.hour }
    meet_link { "https://meet.example.com/#{SecureRandom.hex(8)}" }
  end
end
