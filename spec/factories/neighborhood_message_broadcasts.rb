FactoryBot.define do
  factory :neighborhood_message_broadcast do
    conversation_type { 'Neighborhood' }
    content { 'Contenu de la diffusion' }
    title { 'Titre de la diffusion' }
    archived_at { nil }
    status { 'draft' }
  end
end
