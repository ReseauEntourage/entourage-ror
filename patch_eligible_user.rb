content = File.read('spec/services/badges_service_spec.rb')
# Fix the eligible_user? test failing on validation of partner
content.gsub!("create(:public_user, targeting_profile: 'partner')", "create(:public_user, targeting_profile: 'partner', partner: create(:partner))")
File.write('spec/services/badges_service_spec.rb', content)
