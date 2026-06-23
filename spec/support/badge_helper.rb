module BadgeHelper
  def default_badges_json
    [
      { 'name' => 'bienvenue',         'active' => false, 'awarded_at' => nil, 'metadata' => {} },
      { 'name' => 'premier_contact',   'active' => false, 'awarded_at' => nil, 'metadata' => {} },
      { 'name' => 'moteur_rencontres', 'active' => false, 'awarded_at' => nil, 'metadata' => { 'current' => 0, 'target' => 3 } },
      { 'name' => 'fidele_papotages',  'active' => false, 'awarded_at' => nil, 'metadata' => { 'current' => 0, 'target' => 3 } },
      { 'name' => 'voix_presente',     'active' => false, 'awarded_at' => nil, 'metadata' => { 'current' => 0, 'target' => 3 } }
    ]
  end
end

RSpec.configure do |config|
  config.include BadgeHelper
end
