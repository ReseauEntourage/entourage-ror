content = File.read('spec/controllers/api/v1/users_controller_spec.rb')
# It currently has my "badges" => ... patch everywhere.
# I'll revert it first.
`git checkout spec/controllers/api/v1/users_controller_spec.rb`
content = File.read('spec/controllers/api/v1/users_controller_spec.rb')

badges_json = ', "badges" => [{ "tag" => "bienvenue", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 1 }, { "tag" => "premier_contact", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 1 }, { "tag" => "moteur_rencontres", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 3 }, { "tag" => "fidele_papotages", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 6 }, { "tag" => "voix_presente", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 3 }]'

# Add to your own profile check
content.sub!(/'unread_count' => 0/, "'unread_count' => 0#{badges_json}")
# Add to 'me' shortcut check
content.sub!(/'unread_count' => 0/, "'unread_count' => 0#{badges_json}")
# Someone else profile check also uses full_user_serializer_options which now includes badges
content.sub!(/'unread_count' => 0/, "'unread_count' => 0#{badges_json}")

File.write('spec/controllers/api/v1/users_controller_spec.rb', content)
