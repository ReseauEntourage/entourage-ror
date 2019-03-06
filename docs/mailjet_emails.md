# Variables dans Mailjet

Elles s'insèrent en écrivant {{var: nom_variable:”valeur par défaut”}} 

2 types de variables : 
- celles partagées par tous les mails
- celles qu’un certain mail peut utiliser (une variable peut être utilisée dans plusieurs mails bien sur)


Tous les templates partagent les variables mentionnées dans GitHub dans la section qui commence par:  
`variables.reverse_merge!(
first_name: user.first_name,
user_id: UserServices::EncodedId.encode(user.id),
webapp_login_link: (ENV['WEBSITE_URL'] + '/app?auth=' + auth_token),
login_link: (ENV['WEBSITE_URL'] + '/deeplink/feed?auth=' + auth_token)
 )
 `

## Variables partagées
- first_name prénom     
- user_id 
- login_link: sert à auto-logger le user dans la webapp s’il est sur desktop, ou s’il est sur mobile mais sans l’app, et à ouvrir sa session dans l’app s’il est sur mobile avec l’app. Il expire au bout de 7 jours.
- webapp_login_link: sert à auto-logger le user forcément dans la webapp, même s’il a l’app et ouvre le mail sur son tel. Pratique pour faire découvrir la webapp. Il expire au bout de 7 jours. En vue de sécuriser le réseau, et parce que la plupart des mails sont ouverts dans les 2h après réception, ce temps d'expiration pourra être réduit à 2h (EN-961).


## Variables "par template"
Toutes les autres variables sont définies au niveau de chaque mail. Pour trouver celles disponibles pour un mail, chercher son id sur la page [URL]
L’id du mail est dans l’URL de son mode édition dans Mailjet, par exemple https://app.mailjet.com/template/311246/build pour le mail de bienvenue, id = 311246.

En cherchant 312279 sur la page “mailer”???[URL] , on voit qu’il a comme variable entourage_title (uniquement, pas entourage_id). 

- entourage_id	
- entourage_url: contient un token d'auto-login qui expire au bout de 7 jours
- entourage_title	
- action_url: égal à entourage_url, ce serait bien d'avoir entourage_url partout (EN-960)
- action_title: égal à entourage_title, ce serait bien d'avoir entourage_title partout (EN-960)
- action_share_url: deeplink vers l'entourage, SANS lien d'auto login. 

### Répartition de ces variables dans les templates à date (06/03/2019)
| Nom dans Mailjet                         | ID du template | Besoin de variables par entourage   | entourage_id | entourage_url | entourage_title | action_url | action_title | action_share_url | event_date_time | event_place_name | event_address_url | volunteering_form_url | action_success_url | action_support_url | action_author_type | action_type |
|------------------------------------------|----------------|-------------------------------------|--------------|---------------|-----------------|------------|--------------|------------------|-----------------|------------------|-------------------|-----------------------|--------------------|--------------------|---------------------|-------------|
| x. Recommandations Hebdo                 | 452757         |                                     |              |               |                 |            |              |                  |                 |                  |                   |                       |                    |                    |                     |             |
| 1.0 Bienvenue                            | 311246         | NA                                  |              |               |                 |            |              |                  |                 |                  |                   |                       |                    |                    |                     |             |
| 1.4 Simple comme bonjour                 | 456172         | NA                                  |              |               |                 |            |              |                  |                 |                  |                   |                       |                    |                    |                     |             |
| 1.3 Besoin d'aide ?                      | 452755         | NA                                  |              |               |                 |            |              |                  |                 |                  |                   |                       |                    |                    |                     |             |
| 1.5 Toc Toc                              | 456175         | NA                                  |              |               |                 |            |              |                  |                 |                  |                   |                       |                    |                    |                     |             |
| 1.6 Dernier appel pour sauver le monde   | 456194         | NA                                  |              |               |                 |            |              |                  |                 |                  |                   |                       |                    |                    |                     |             |
| 2.1 Confrmation action créée             | 312279         |                                     |              |               | Oui             |            |              | à rajouter       |                 |                  |                   |                       |                    |                    |                     |             |
| 2.2 Suivi action 1 j+10                  | 452754         | groups: {                    action |              |               |                 |            |              | à rajouter       |                 |                  |                   |                       |                    |                    |                     |             |
| 2.3 Suivi action 2 j+20                  | 451123         | groups: {                    action |              |               |                 |            |              | à rajouter       |                 |                  |                   |                       | Oui                | Oui                |                     |             |
| 2.4A Action aboutie succès               | 366621         |                                     |              |               |                 |            | Oui          | à rajouter       |                 |                  |                   | Oui                   |                    |                    | Oui                 | Oui         |
| 2.1 EVENT Confirmation event créé        | 491291         |                                     |              |               | Oui             |            |              | à rajouter       | à rajouter      | à rajouter       |                   |                       |                    |                    |                     |             |
| 2.2. EVENT SUIVI Organisateur Email j-1  | 513115         |                                     |              | Oui           | Oui             |            |              | à rajouter       | à rajouter      | à rajouter       |                   |                       |                    |                    |                     |             |
| 2.3 Suivi event j+1                      | 491294         |                                     |              |               | Oui             |            |              |                  |                 |                  |                   |                       |                    |                    |                     |             |
| 2.B.1 EVENT Confirmation Participant J+0 | 478397         |                                     |              |               | Oui             |            |              | à rajouter       | Oui             | Oui              | Oui               |                       |                    |                    |                     |             |
| 2.B.2. EVENT SUIVI Participant J-1       | 491289         |                                     |              | Oui           | Oui             |            |              | à rajouter       | à rajouter      | à rajouter       |                   |                       |                    |                    |                     |             |
| x. Nouveau(x) messages                   | 546676         |                                     |              |               |                 |            |              |                  |                 |                  |                   |                       |                    |                    |                     |             |
