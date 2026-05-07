content = File.read('app/serializers/v1/users/summary_serializer.rb')
content.gsub!("def badges", "def include_badges?\n        scope[:badges]\n      end\n\n      def badges")
File.write('app/serializers/v1/users/summary_serializer.rb', content)
