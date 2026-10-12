#!/usr/bin/env ruby
# frozen_string_literal: true

# Lance rubocop sur les fichiers Ruby modifiés depuis la base et n'affiche que les
# offenses situées sur des lignes ajoutées ou modifiées : le code existant viole
# beaucoup de règles de .rubocop.yml, et ce bruit n'est pas imputable à la branche.
#
# Usage : ruby .claude/skills/quality-check/rubocop_diff.rb [base]   (base par défaut : origin/master)
# Compare le working tree (changements non commités compris) au merge-base avec la base.

require 'json'
require 'open3'

base = ARGV[0] || 'origin/master'

merge_base, status = Open3.capture2('git', 'merge-base', base, 'HEAD')
abort("git merge-base #{base} HEAD a échoué") unless status.success?

diff, status = Open3.capture2('git', 'diff', '-U0', '--diff-filter=AM', merge_base.strip)
abort('git diff a échoué') unless status.success?

changed = Hash.new { |hash, key| hash[key] = [] }
file = nil
diff.each_line do |line|
  if line.start_with?('+++ ')
    path = line.sub(%r{\A\+\+\+ (b/)?}, '').strip
    file = path == '/dev/null' ? nil : path
  elsif file && (match = line.match(/\A@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@/))
    start = match[1].to_i
    count = (match[2] || '1').to_i
    changed[file] << (start...(start + count)) if count.positive?
  end
end

ruby_files = changed.keys.select { |path| path.match?(/\.(rb|rake)\z|\AGemfile\z/) && File.exist?(path) }
if ruby_files.empty?
  puts 'Aucun fichier Ruby modifié.'
  exit 0
end

output, = Open3.capture2('bundle', 'exec', 'rubocop', '--format', 'json', '--force-exclusion', *ruby_files)
report = JSON.parse(output)

kept = []
by_cop = Hash.new(0)
ignored = 0
report.fetch('files').each do |entry|
  ranges = changed[entry['path']]
  entry['offenses'].each do |offense|
    line = offense.dig('location', 'start_line')
    if ranges.any? { |range| range.cover?(line) }
      kept << format('%<path>s:%<line>d:%<col>d [%<cop>s] %<message>s',
                     path: entry['path'], line: line, col: offense.dig('location', 'start_column'),
                     cop: offense['cop_name'], message: offense['message'])
      by_cop[offense['cop_name']] += 1
    else
      ignored += 1
    end
  end
end

puts kept
puts
puts 'Par règle :'
by_cop.sort_by { |cop, count| [-count, cop] }.each { |cop, count| puts format('%5d  %s', count, cop) }
puts
puts "#{kept.size} offense(s) sur les lignes modifiées, #{ignored} préexistante(s) ignorée(s), #{ruby_files.size} fichier(s) analysé(s)."
