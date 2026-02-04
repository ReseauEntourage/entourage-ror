# generates a markdown table of the mailjet variables exposed to each template
# run with:
# RAILS_ENV=test d rails runner scripts/mailjet_doc.rb

raise unless EnvironmentHelper.env == :test

dev_env = Dotenv::Environment.new('.env.development')
ENV['MAILJET_API_KEY']    ||= dev_env['MAILJET_API_KEY']
ENV['MAILJET_SECRET_KEY'] ||= dev_env['MAILJET_SECRET_KEY']
load 'config/initializers/mailjet.rb'

include FactoryBot::Syntax::Methods

def cleanup_db
  User.delete_all
  Entourage.delete_all
  JoinRequest.delete_all
  ChatMessage.delete_all
end

cleanup_db

user = create :public_user
action = create :entourage
action_join_request = create :join_request, user: user, joinable: action, role: :member, status: :accepted
event = create(:outing).reload
event_join_request = create :join_request, user: user, joinable: event, role: :participant, status: :accepted
create :chat_message, messageable: event, user: event.user

headers = []

[
  MemberMailer.welcome(user),
  MemberMailer.onboarding_day_8(user),
  MemberMailer.onboarding_day_14(user),
  MemberMailer.reactivation_day_20(user),
  MemberMailer.action_follow_up_day_15(action),
  GroupMailer.event_created_confirmation(event),
  UnreadReminderEmail.delivery(UnreadReminderEmail::Presenter.new(user)),
  DigestEmailService.delivery(user, [action.id, event.id], suggested_postal_code: '75001'),
].each do |delivery|
  headers.push delivery.header
end

cleanup_db

template_names = Hash[Mailjet::Template.all(limit: 1000).map{|t| [t.id, t.name]}]

def template_tags template_id
  # the SDK is completely broken on this endpoint so this is an awful workaround
  Mailjet::Template_detailcontent.resource_path = 'REST/template/id/detailcontent'
  Mailjet::Template_detailcontent.action = 'detailcontent'
  Mailjet::Template_detailcontent.find(template_id) rescue nil
  template = Mailjet::Template_detailcontent.all.first

  template.html_part.scan(/\{\{.*?\}\}|\{%.*?%\}/)
end

def template_variables template_id
  template_tags(template_id).map { |m| m.scan(/var:([a-z0-9_\.]+)/) }.flatten.uniq
end

# value_count = {}

# headers.each do |headers|
#   headers.map do |header|
#     value_count[header.name] ||= Hash.new(0)
#     value_count[header.name][header.value] += 1
#   end
# end

# common_header_values = []

# majority = (headers.count / 2.0).ceil

# value_count.each do |name, value_count|
#   value_count.each do |value, count|
#     if count >= majority
#       common_header_values.push [name, value, "#{count}/#{headers.count}"]
#     end
#   end
# end

# puts "Ces headers ont les valeurs suivantes, sauf si précisé"
# common_header_values.each do |name, value, freq|
#   next if name.in? ["To", "Mime-Version", "Content-Type", 'X-MJ-TemplateLanguage', 'X-MJ-TemplateErrorReporting']
#   p [name, value]
# end

data = []

headers.each do |headers|
  h = {}
  headers.map do |header|
    h[header.name] ||= []
    h[header.name].push header.value
  end
  a = h.map { |k, a| [k, a.length == 1 ? a[0] : a]}
  # a -= common_header_values.map { |a| a[0..1]}
  # a.delete_if { |k, _| k.in? ['To', 'Content-Type', 'Mime-Version']}
  a = Hash[a]
  mdata = {}
  mdata[:from] = headers['From'].addresses.first
  mdata[:campaign] = a.delete('X-Mailjet-Campaign')
  mdata[:template] = a.delete('X-MJ-TemplateID').to_i
  mdata[:vars] = JSON.parse(a.delete('X-MJ-Vars')).keys
  mdata[:template_vars] = template_variables(mdata[:template])
  # mdata[:unsubscribe_category] = JSON.parse(a.delete('X-MJ-EventPayload'))['unsubscribe_category']
  data.push mdata
end

data.each do |mdata|
  campaigns = Mailjet::Campaign.all(
    custom_campaign: mdata[:campaign],
    from: mdata[:from]
  )
  case campaigns.count
  when 1
    mdata[:campaign_id] = campaigns.first.id
  when 0
    mdata[:campaign_id] = nil
  else
    raise "campaigns.count = #{campaigns.count} for #{mdata[:campaign]}"
  end
end

vars = {}
data.each.with_index do |m, i|
  template_vars_except_nested = m[:template_vars].reject { |v| v['.'] != nil }
  (m[:vars] + template_vars_except_nested).uniq.each do |var|
    vars[var] ||= {count: 0, first_occurence: i}
    vars[var][:count] += 1
  end
end

vars = vars.sort_by do |var, metadata|
  [-metadata[:count], metadata[:first_occurence], var.length]
end

shared_vars = []
unique_vars = []
vars.each do |var, metadata|
  if metadata[:count] > 1
    shared_vars.push var
  else
    unique_vars.push var
  end
end

# put side to side the columns for similarly named (entourage|action)_ vars
#
# vars2 = []
# loop do
#   break if vars.empty?
#   var = vars.shift
#   vars2.push var
#   match = var.match(/^(action|entourage)_/)
#   next if match.nil?
#   other = (['action', 'entourage'] - [match[1]])[0]
#   subst = var.gsub(match[1], other)
#   var = vars.delete subst
#   vars2.push var if var
# end
# vars = vars2

lines = []
r = ['Nom dans Mailjet', :campagne, :template] + shared_vars
lines.push r

def mailjet_id decimal
  # it's a base 62 conversion
  alphabet = ['0'..'9', 'a'..'z', 'A'..'Z'].flat_map(&:to_a)
  output = []
  while decimal != 0
    output.unshift alphabet[decimal % alphabet.size]
    decimal /= alphabet.size
  end
  output.join
end

def nbsp string
  string.gsub(' ', '&nbsp;')
end

data.each do |m|
  a = [
    "[#{nbsp template_names[m[:template]]}](https://app.mailjet.com/template/#{m[:template]}/build)",
    m[:campaign_id] ? "[#{m[:campaign]}](https://app.mailjet.com/stats/campaigns-basic/#{mailjet_id m[:campaign_id]})" : m[:campaign],
    "[#{m[:template]}](https://app.mailjet.com/resource/template/#{m[:template]}/render)"
  ]
  shared_vars.each do |var|
    used = var.in?(m[:template_vars])
    defined = var.in?(m[:vars])
    val =
      if defined && used
        'Oui'
      elsif defined && !used
        '(Oui)'
      elsif !defined && used
        'Manquante'
      elsif !defined && !used
        nil
      else
        raise
      end

    a.push val
  end
  lines.push a

  m[:unique_vars] = {}

  unique_vars.each do |var|
    used = var.in?(m[:template_vars])
    defined = var.in?(m[:vars])
    val =
      if defined && used
        'Oui'
      elsif defined && !used
        '(Oui)'
      elsif !defined && used
        'Manquante'
      elsif !defined && !used
        nil
      else
        raise
      end

    m[:unique_vars][var] = val if val
  end
end

def calc_widths lines
  widths = []
  lines.each do |line|
    line.each.with_index do |col, i|
      widths[i] ||= 0
      widths[i] = [widths[i], col.to_s.length].max
    end
  end
  widths
end

def line a, widths
  '| ' + a.zip(widths).map { |word, width| word.to_s.ljust(width, ' ') }.join(' | ') + " |\n"
end

def spacer widths
  '|' + widths.map {|w| '-' * (w+2) }.join('|') + "|\n"
end

start_comment = '<!--generated:start-->'
end_comment   = '<!--generated:end-->'
timestamp = Time.zone.now.strftime('%d/%m/%Y')
widths = calc_widths(lines)

table = StringIO.new

table.puts start_comment
table.puts '### Répartition de ces variables dans les templates'
table.puts "_Mis à jour le #{timestamp}_"
table.puts
table.puts line(lines[0], widths)
table.puts spacer(widths)
lines[1..-1].each do |line|
  table.puts line(line, widths)
end

table.puts
table.puts '(Oui) : variable disponible mais pas utilisée dans le template'
table.puts

table.puts '### Variables uniques'
data.each do |m|
  next unless m[:unique_vars].any?
  table.puts "#### #{template_names[m[:template]]} (#{m[:campaign]}, #{m[:template]})"
  lines = m[:unique_vars].to_a.transpose
  widths = calc_widths(lines)
  table.puts
  table.puts line(lines[0], widths)
  table.puts spacer(widths)
  table.puts line(lines[1], widths)
  table.puts
end

table.print end_comment

regexp = Regexp.new(
  [Regexp.quote(start_comment), '.*', Regexp.quote(end_comment)].join,
  Regexp::MULTILINE
)

File.open("#{Rails.root}/docs/mailjet_emails.md", 'r+') do |file|
  content = file.read
  table.rewind
  file.rewind
  file.write content.gsub(regexp, table.read)
  file.flush
  file.truncate(file.pos)
end
