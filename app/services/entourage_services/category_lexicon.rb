module EntourageServices
  class CategoryLexicon

    def initialize(text:)
      @text = text
    end

    def category
      counter = json.keys.inject({}) do |h, key|
        h[key] = (json[key] & text_words).count
        h
      end
      best_category = counter.max_by{|k,v| v}
      best_category[0].to_s if best_category[1] > 0
    end

    private
    attr_reader :text

    def text_words
      text.split(' ')
    end

    def json
      {
          "mat_help": ['besoin', 'aide', 'distribution', 'alimentaire', 'boisson chaude', 'boulangerie', 'denrées', 'chips', 'soupe', 'thon', 'jambon', 'blanc de dinde', 'vêtement', 'dépôt', 'crème', 'pharmacie', 'savon', 'parfum', 'parapluie', 'livres', 'donner (etc)', 'cahier', 'stylo', 'poussette', 'radio', 'poste de radio', 'pompe insuline', 'duvet', 'sac de couchage', 'chaussures', 'hygiène', 'crème hydratante', 'gâteau', 'chocolat', 'tickets restau', 'lait', 'serviettes', 'jouet', 'kleenex', 'tomates', 'pomme de terre', 'couche', 'sel', 'pantalon', 'pull', 'logement', 'nourriture', 'gants', 'manteaux', 'bottes', 'sucre', 'shampoing', 'dentifrice', 'portables', 'croquettes', 'couvertures', 'baume main', 'matelas', 'lunettes', 'écharpe', 'bonnet', 'plaid', 'sac à dos', 'pyjama', 'tickets de bus', 'mobicarte', 'hébergement', 'jean', 'lit', 'chaussettes', 'couette', 'robe', 'hôtel', 'téléphone', 'baskets', 'taille', 'chambre', 'basquettes', 'petit dej', 'drap', 'vélo', 'eau', 'sweat', 'lingettes', 'appart', 'bons cadeaux', 'carte prépayée', 'tente', 'collecte', 'abri', 'clopes', 'cigarettes', 'studio', 'faim', 'caleçons', 'chemises', 'veste', 'frites', 'doudoune', 'habits', 'collants', 'bagage', 'tickets de transport', 'héberger', 'nourrir', 'couvert', 'coucher'],
          "non_mat_help": ['besoin', 'maraude', 'aide', 'partager', 'petits boulots', 'papiers', 'douche', 'emplois', 'boulots', 'traduction', 'bénévoles', 'toilette', 'internet', 'électricité', 'cours', 'ménages', 'kiné', 'kinésithérapeute', 'soigner', 'soulager', 'quelqu’un qui parle', 'job', 'traducteur', 'bénévolat', 'quelqu’un parle', 'quelqu’un parle-t-il', 'médecin', 'russophone', 'roumain', 'hongrois', 'informatique', 'polonais', 'covoiturage', 'garder des affaires', 'italien', 'démarche administrative', 'serbe', 'couture', 'volontaires', 'dentiste', 'rédaction', 'conseils', 'travail', 'coup de main', 'lessives', 'vétérinaire', 'voiture', 'travaux', 'travaille', 'bureautique', 'coiffeur', 'anglais', 'retravailler', 'soutien', 'camionnette', 'soins'],
          "social": ['café', 'atelier', 'pêche', 'apéro', 'rencontrer', 'rencontre', 'soirée', 'remercier', 'repas', 'visite', 'galette des rois', 'partager', 'chaleur humaine', 'coeur', 'entour’apéro', 'goûter', 'solidaire', 'fraternel', 'réconforter', 'remonter le moral', 'humain', 'sport', 'veiller', 'déprime', 'tenir compagnie', 'anniversaire']
      }
    end

  end
end
