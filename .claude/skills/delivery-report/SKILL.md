---
name: delivery-report
description: "Publier ou mettre à jour le rapport d'une branche ou d'un sujet d'entourage-ror sous forme d'artifact, au format unifié de l'équipe. Six sections fixes : ce qui a été livré, comment tester (commandes copiables), contrôles (sécurité, performance, qualité, testabilité, données personnelles, compatibilité apps, migrations), déploiement, points ouverts, méthode et historique. À utiliser pour « rapport », « compte rendu », « récap de la branche », « fais l'artifact », « comment tester », « note de livraison », ou à la fin de branch-review et datadog-investigation."
argument-hint: "[branche, ticket EN-xxxx, ou URL d'un rapport existant à mettre à jour]"
---

# Rapport unifié

Cible : $ARGUMENTS (par défaut : la branche courante).

Tous les rapports d'entourage-ror ont la même forme, pour qu'on les lise et les compare sans effort : même gabarit (`.claude/skills/delivery-report/template.html`), mêmes six sections, dans le même ordre, avec le même style. Seul le contenu change.

## 1. Retrouver un rapport existant

Un sujet a **un seul** rapport, mis à jour au fil de l'eau (même URL).

- URL fournie : la lire avec l'outil Artifact (`action: "read"`) et repartir de cette version.
- Sinon : `Artifact` `action: "list"` et chercher un titre qui commence par le ticket (`EN-9582 …`) ou le nom de la branche. Si un rapport existe, le lire et le mettre à jour par son `url`.
- Sinon : en créer un nouveau.

## 2. Rassembler la matière

```bash
git fetch origin master --quiet
git branch --show-current
git log --reverse --format='%h %s' origin/master..HEAD
git diff --stat origin/master...HEAD
```

- **Livré** : lire les commits et le diff ; une entrée par changement de comportement (avant / après / fichiers clés), pas par commit technique.
- **Contrôles** : reprendre les constats des skills `*-check` déjà lancés dans la conversation, tels quels (format : `findings-format.md` dans ce dossier). Si aucun n'a tourné, proposer `/branch-review` ; sinon, marquer les thèmes non contrôlés `Non fait`. Ne jamais marquer `OK` un thème qui n'a pas été contrôlé.
- **Specs** : le résultat réel de la dernière exécution (`N examples, N failures`), avec la date. Sans exécution, l'écrire.

## 3. Écrire « Comment tester »

C'est la section que la personne utilise le plus : elle valide les fonctionnalités par des appels d'API plutôt que dans les apps. Chaque étape a une action, une commande copiable et un résultat attendu précis (statut HTTP, champ, valeur).

- Les variables restent des variables : `$API` (URL de base, `http://localhost:3000` ou la préprod), `$API_KEY` (une clé de `API_KEYS_IOS` / `API_KEYS_ANDROID` du `.env` local), `$TOKEN`. Ne jamais écrire un vrai token, une vraie clé, un vrai téléphone.
- Obtenir un token :

  ```bash
  curl -s -X POST "$API/api/v1/login" -H "X-API-KEY: $API_KEY" -H 'Content-Type: application/json' \
    -d '{"user":{"phone":"+33600000000","secret":"…"}}' | jq -r '.user.token'
  ```

- Appel type :

  ```bash
  curl -s "$API/api/v1/outings/123?token=$TOKEN" -H "X-API-KEY: $API_KEY" | jq '.outing | {id, metadata}'
  ```

- Couvrir : le cas nominal, au moins un refus (non-propriétaire, sans token), les valeurs limites trouvées pendant le développement, et le back-office si un écran change.
- Si la personne préfère un plan de recette à cocher dans un document partagé, le faire en plus, pas à la place de cette section.
- Si la branche change ce que les apps appellent ou affichent, la recette partagée avec iOS et Android vit dans la fiche fonctionnalité (skill `feature-sheet`) : y renvoyer par un lien plutôt que recopier ses tests, et proposer de la créer si elle n'existe pas.

## 4. Remplir le gabarit

1. L'outil Artifact exige de charger le skill `artifact-design` avant d'écrire la page : le charger, mais **garder le style du gabarit tel quel**. C'est le système de design des rapports du projet ; il prime sur les choix de design par défaut.
2. Copier le gabarit dans le dossier scratchpad de la session sous un nom stable, par exemple `rapport-EN-9582.html` ou `rapport-<branche>.html`. Pour une mise à jour dans la même session, réutiliser le même fichier.
3. Remplacer chaque `{{…}}`. Dupliquer les blocs entre `<!-- RÉPÉTER -->` et `<!-- /RÉPÉTER -->` autant que nécessaire, puis supprimer les commentaires de gabarit et tout `{{…}}` restant.
4. Règles de forme :
   - les six sections sont toujours présentes, dans l'ordre ; une section sans objet garde son titre et dit pourquoi en une phrase (`<p class="na">Sans objet : …</p>`) ;
   - le tableau des contrôles garde ses sept lignes ;
   - le bloc « chiffres clés » n'existe que si des chiffres sont le cœur du sujet (2 ou 4 chiffres, avec leur source) ;
   - `<title>` : le ticket et le sujet en quelques mots (`EN-9582 PMR et enfants bienvenus`), stable d'une mise à jour à l'autre ;
   - eyebrow : `Livraison`, `Audit` ou `Investigation`, puis la branche, le ticket, la date ;
   - chaque id `cmd-N` est unique (les boutons Copier s'y réfèrent).
5. Rédaction : en français, phrases courtes, du point de vue de l'utilisateur ou de l'équipe (« l'organisateur peut indiquer que l'évènement est accessible PMR »), termes du code en `<code>`. Aucune donnée personnelle de production (noms, téléphones, contenus) : des volumes et des agrégats seulement.
6. **Journal** (section 6) : une ligne datée par publication, la plus récente en haut, qui dit ce qui a changé.

## 5. Publier

- Première publication : `Artifact` avec `file_path`, `icon: "report"` et une `description` d'une phrase.
- Mise à jour dans la même session : republier le même fichier, sans `icon`.
- Mise à jour d'un rapport d'une session précédente : le lire d'abord (`action: "read"`), modifier la version lue, publier avec son `url`.
- Donner le lien à la personne en une ligne. Le rapport est privé par défaut : c'est à elle de le partager.

Un audit de sécurité qui révèle des failles ouvertes est réservé à un public restreint : le dire à la personne avant qu'elle partage le lien, et ne détailler que les failles corrigées dans une version destinée à un public plus large.
