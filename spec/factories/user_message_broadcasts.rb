FactoryBot.define do
  factory :user_message_broadcast do
    conversation_type { 'Entourage' }
    area_type { 'list' }
    areas { ['75'] }
    content { 'Contenu de la diffusion' }
    goal { 'ask_for_help' }
    title { 'Titre de la diffusion' }
    archived_at { nil }
    status { 'sent' }
  end
end
