function pluralize(count, singular, plural) {
  return `${count} ${count > 1 ? plural : singular}`
}

export default function statsTemplate(data) {
  return `<h3>Statistiques de la recherche</h3>
    <h4>${pluralize(data.encounter_count, 'rencontre', 'rencontres')}</h4>
    <h4>${pluralize(data.tourer_count, 'maraudeur actif', 'maraudeurs actifs')}</h4>
    <h4>${pluralize(data.tour_count, 'maraude réalisée', 'maraudes réalisées')}</h4>`
}
