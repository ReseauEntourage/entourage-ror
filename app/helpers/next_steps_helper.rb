# Back-office display of « Votre prochain pas » (EN-9473), on the user page.
module NextStepsHelper
  NEXT_STEP_KINDS = {
    'outing' => 'Événement',
    'neighborhood' => 'Groupe',
    'action' => 'Entraide',
    'content_path' => 'Parcours de contenus',
    'smalltalk' => 'Bonnes ondes',
    'poi' => 'Lieu solidaire',
    'post_message' => 'Écrire dans un groupe',
    'become_ambassador' => 'Devenir bénévole (webinaire)'
  }.freeze

  NEXT_STEP_ENDING_STATUSES = {
    'expired' => 'expirée',
    'closed' => 'close (cible disparue)',
    'realised' => 'réalisée'
  }.freeze

  def next_step_kind_label kind
    NEXT_STEP_KINDS.fetch(kind, kind)
  end

  def next_step_ending_status_label status
    NEXT_STEP_ENDING_STATUSES.fetch(status, status)
  end

  def next_step_time time
    time.strftime('%d/%m/%Y à %Hh%M')
  end

  # Where the engine's segment comes from (NextSteps::EffectiveSegment)
  def next_step_segment_source_label segment, user
    case segment.source
    when 'computed'
      computed_at = user.user_segment&.segment_computed_at
      computed_at ? "calculé le #{next_step_time(computed_at)}" : 'calculé'
    when 'assumed_new' then 'aucun segment calculé et aucun engagement : traité comme nouvel utilisateur'
    when 'assumed_returning' then 'aucun segment calculé mais un engagement passé : traité comme de retour après 30 jours'
    when 'team' then "membre de l'équipe : traité comme Contributeur"
    else segment.source
    end
  end

  # The targets of a suggestion, linked to their back-office page.
  def next_step_targets_links next_step
    links = if next_step.kind == 'content_path'
      resources = next_step.resources.index_by(&:id)
      next_step.target_ids.filter_map { |id| resources[id] }.map { |resource| link_to(resource.name, admin_resource_path(resource)) }
    elsif (target = next_step.target)
      [next_step_target_link(target)]
    else
      []
    end

    safe_join(links, ', ')
  end

  # The body of GET /api/v1/next_steps/current for this suggestion
  def next_step_api_payload next_step, user
    { next_step: ::V1::NextStepSerializer.new(next_step, user: user).as_json }
  end

  # ... as the apps receive it: same JSON encoding as `render json:`
  def next_step_api_json payload
    JSON.pretty_generate(JSON.parse(payload.to_json))
  end

  private

  def next_step_target_link target
    case target
    when Entourage then link_to(target.title, admin_entourage_path(target))
    when Neighborhood then link_to(target.name, edit_admin_neighborhood_path(target))
    when Poi then link_to(target.name, admin_poi_path(target))
    else "#{target.class.name} n°#{target.id}"
    end
  end
end
