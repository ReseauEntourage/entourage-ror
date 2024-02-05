module GroupService
  NAME = {
    action: ['l’', 'une ', 'action', :f],
    outing: ['l’', 'un ', 'évènement', :m],
    group: ['le ', 'un ', 'groupe', :m],
  }

  def self.name group, form=nil
    l, u, name, g = NAME[group.group_type.to_sym] || ['le ', 'un ', 'groupe']

    case form
    when :l
      [l, name].join
    when :u
      [u, name].join
    when :g
      g
    else
      name
    end
  end

  def self.postal_code group
    group.try(:postal_code)
  end

  def self.g group, word
    parts = word.split('.', 2)
    case name(group, :g)
    when :m
      parts[0]
    when :f
      parts.join
    end
  end
end
