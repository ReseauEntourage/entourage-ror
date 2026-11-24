# Entourage (API Rails + back-office)

## Production

- **Claude ne se connecte pas à la base de prod sans instruction explicite de ma part, et n'y écrit jamais.** Si une écriture est nécessaire, me la proposer : je la lance moi-même avec `! ...`.
- **Aucune commande `heroku` sur la prod sans mon accord explicite pour cette commande**, même en lecture (`logs`, `ps`, `releases`, `config`, `pg:*`), y compris cachée dans un script. Sinon, me proposer de la lancer avec `! heroku ...`. Un refus (règle, classifieur) ne se contourne pas.
- Jamais `heroku pg:psql`, `heroku run`, `releases:info` ni `pg:credentials`.
- Ne publier (artifact, doc, commit) que des résultats agrégés : jamais d'identifiants d'utilisateurs, de numéros ni de contenus.
- `.claude/settings.json` bloque ou fait confirmer ces commandes ; il ne remplace pas cette consigne.

## Développement

`bin/rails` en développement tape la base de **preprod** partagée : ne jamais y migrer ni y écrire sans accord.
