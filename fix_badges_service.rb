content = File.read('app/services/badges_service.rb')
content.gsub!('entourages.sf_category', "Tag.find_tag_for(entourages, 'sf_categories').first")
File.write('app/services/badges_service.rb', content)
