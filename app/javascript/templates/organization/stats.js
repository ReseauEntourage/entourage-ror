export function statsTemplate(data) {
  const pluralize = (count, singular, plural) => {
    return count === 1 ? `${count} ${singular}` : `${count} ${plural}`;
  };

  return `
    <h3>Statistiques de la recherche</h3>
    <h4>${pluralize(data.encounter_count, 'rencontre', 'rencontres')}</h4>
    <h4>${pluralize(data.tourer_count, 'maraudeur actif', 'maraudeurs actifs')}</h4>
    <h4>${pluralize(data.tour_count, 'maraude réalisée', 'maraudes réalisées')}</h4>
  `;
}
