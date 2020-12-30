FactoryGirl.define do
  factory :conversation_message_broadcast do
    area 'dep_75'
    content 'Contenu de la diffusion'
    goal 'ask_for_help'
    title 'Titre de la diffusion'
    archived_at nil
    status 'draft'
  end
end
