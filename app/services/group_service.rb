module GroupService
  NAME = {
    tour: ['la ', 'une ', 'maraude'],
    action: ['l’', 'une ', 'action'],
    outing: ['l’', 'un ', 'évènement'],
  }

  COMMUNITY_NAME = {
    [:pfp, :outing] => ['la ', 'une ', 'sortie'],
    [:pfp, :neighborhood] => ['le ', 'un ', 'voisinage'],
    [:pfp, :private_circle] => ['le ', 'un ', 'voisinage']
  }

  def self.name group, form=nil
    l, u, name =
      COMMUNITY_NAME[[group.community.slug.to_sym, group.group_type.to_sym]] ||
      NAME[group.group_type.to_sym] ||
      ['le ', 'un ', 'groupe']
    case form
    when :l
      [l, name].join
    when :u
      [u, name].join
    else
      name
    end
  end
end
