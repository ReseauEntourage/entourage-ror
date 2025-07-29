#!/usr/bin/env ruby

# Permet de générer des emails avec des templates du projet
# Par exemple, dans la version mobile, quand on reporte un utilisateur, on fait un appel à l'api
# cet appel permet de notifier un modérateur sur le "report" de cet utilisateur, cf AdminMailer.user_report

require 'open3'
require 'tempfile'

BASH_GLOB = 'app/views/*_mailer/*\.htm*'
MAILCHIMP_ENDPOINT = 'https://templates.mailchimp.com/services/html-to-text/'
require 'yaml'

def text_version_filename html_version_filename
  html_version_filename.sub(/\.html?(\.erb)?$/, '.text\1')
end

def color code, text
  "\e[#{code}m#{text}\e[0m"
end

def print_error_details text
  puts color 31, 'Error'
  text.to_s.each_line do |line|
    puts "    #{color 31, '>'} #{line}"
  end
  puts
end

class CurlError < StandardError; end

def generate_text_version file
  print "  #{file} > "
  tmp_file = Tempfile.new('html')
  begin
    html = File.read(file)
    tmp_file.puts html.gsub('<%', '{{').gsub('%>', '}}')
    tmp_file.close

    stdout_str, stderr_str, status = Open3.capture3(
      'curl', '--silent', '--show-error', '--form', "html=<#{tmp_file.path}", MAILCHIMP_ENDPOINT
    )
    raise CurlError if status != 0

    {
      '{{'     => '<%',
      '}}'     => '%>',
      "\u00a0" => ' ',
      / +\n/   => "\n",
    }.each do |pattern, replacement|
      stdout_str.gsub!(pattern, replacement)
    end
    stdout_str.strip!

    out = text_version_filename file
    File.open(out, 'w') { |f| f.puts stdout_str }

    puts color 32, out
    return out

  rescue CurlError
    print_error_details stderr_str
  rescue => e
    print_error_details e
  ensure
    tmp_file.unlink
  end

  return nil
end

def usage
  puts "Usage: #{$PROGRAM_NAME} [mode]"
  puts
  puts 'Modes:'
  puts '  all       All html templates'
  puts '  changed   Only html templates with uncommited changes'
end

if ARGV.count != 1
  usage
  exit 1
end

mode = ARGV[0].to_sym rescue nil

unless [:all, :changed].include?(mode)
  puts "Error: Unknown mode '#{mode}'."
  puts
  usage
  exit 2
end

puts "Generating text versions for #{mode} files:"

files =
  case mode
  when :all
    Dir[BASH_GLOB]
  when :changed
    %x{git diff HEAD --name-only --diff-filter=ACMR -- #{BASH_GLOB}}.split("\n")
  end

files.sort!

text_files = files.map do |file|
  generate_text_version file
end.compact

dangerous_patterns = ['link_to']
text_files.each do |f|
  content = File.read(f)
  patterns = dangerous_patterns.find_all { |pattern| content.match(pattern) }
  if patterns.any?
    puts
    puts "#{color 33, 'Warning:'} dangerous patterns detected in #{f}:"
    puts '  ' + patterns.join(', ')
  end
end
