content = File.read('spec/controllers/api/v1/users_controller_spec.rb')
badges_json = ', "badges" => [{ "tag" => "bienvenue", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 1 }, { "tag" => "premier_contact", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 1 }, { "tag" => "moteur_rencontres", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 3 }, { "tag" => "fidele_papotages", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 6 }, { "tag" => "voix_presente", "active" => false, "awarded_at" => nil, "current" => 0, "target" => 3 }]'

# Find the places where 'unread_count' => 0 is present and append badges
content.gsub!(/'unread_count' => 0/, "'unread_count' => 0#{badges_json}")
File.write('spec/controllers/api/v1/users_controller_spec.rb', content)
