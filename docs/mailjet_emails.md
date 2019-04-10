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

<!--generated:start-->
### Répartition de ces variables dans les templates
_Mis à jour le 10/04/2019_

| Nom dans Mailjet                                                                                                                               | campagne                                                                           | template                                                          | first_name | login_link | unsubscribe_url | user_id | webapp_login_link | entourage_title | entourage_share_url | entourage_url | event_date_time | event_place_name |
|------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|-------------------------------------------------------------------|------------|------------|-----------------|---------|-------------------|-----------------|---------------------|---------------|-----------------|------------------|
| [1.0&nbsp;PROD&nbsp;Bienvenue&nbsp;-&nbsp;Grand&nbsp;Public](https://app.mailjet.com/template/311246/build)                                    | [welcome](https://app.mailjet.com/stats/campaigns-basic/6a0eRK)                    | [311246](https://app.mailjet.com/resource/template/311246/render) | Oui        | Oui        | Oui             | Oui     | (Oui)             |                 |                     |               |                 |                  |
| [1.3&nbsp;Help&nbsp;-&nbsp;OFF&nbsp;-&nbsp;Besoin&nbsp;d'aide&nbsp;-&nbsp;j+8&nbsp;?&nbsp;](https://app.mailjet.com/template/452755/build)     | [onboarding_j_8](https://app.mailjet.com/stats/campaigns-basic/6o06au)             | [452755](https://app.mailjet.com/resource/template/452755/render) | Oui        | Oui        | Oui             | (Oui)   | (Oui)             |                 |                     |               |                 |                  |
| [1.4&nbsp;Onboarding&nbsp;J+14&nbsp;SCB](https://app.mailjet.com/template/456172/build)                                                        | [onboarding_j_14](https://app.mailjet.com/stats/campaigns-basic/6nDUHQ)            | [456172](https://app.mailjet.com/resource/template/456172/render) | Oui        | Oui        | Oui             | Oui     | (Oui)             |                 |                     |               |                 |                  |
| [1.5&nbsp;MAJ&nbsp;Relance&nbsp;J+20&nbsp;Toc&nbsp;Toc&nbsp;Toc](https://app.mailjet.com/template/456175/build)                                | [relance_j_20](https://app.mailjet.com/stats/campaigns-basic/6o06ho)               | [456175](https://app.mailjet.com/resource/template/456175/render) | Oui        | Oui        | Oui             | (Oui)   | (Oui)             |                 |                     |               |                 |                  |
| [1.6&nbsp;Relance&nbsp;J+40&nbsp;Dernier&nbsp;appel&nbsp;pour&nbsp;sauver&nbsp;le&nbsp;monde](https://app.mailjet.com/template/456194/build)   | [relance_j_40](https://app.mailjet.com/stats/campaigns-basic/6o06mi)               | [456194](https://app.mailjet.com/resource/template/456194/render) | Oui        | Oui        | Oui             | (Oui)   | (Oui)             |                 |                     |               |                 |                  |
| [2.1&nbsp;PROD&nbsp;Confirmation&nbsp;action&nbsp;créée&nbsp;à&nbsp;J0](https://app.mailjet.com/template/312279/build)                         | [action_confirmation](https://app.mailjet.com/stats/campaigns-basic/6a0kGu)        | [312279](https://app.mailjet.com/resource/template/312279/render) | Oui        | Oui        | Oui             |         |                   | Oui             | Oui                 |               |                 |                  |
| [2.2&nbsp;SUIVI&nbsp;D'ACTION&nbsp;à&nbsp;j+10](https://app.mailjet.com/template/452754/build)                                                 | [action_suivi_j_10](https://app.mailjet.com/stats/campaigns-basic/6v5CeU)          | [452754](https://app.mailjet.com/resource/template/452754/render) | Oui        | Oui        | (Oui)           | (Oui)   | (Oui)             | Oui             | Oui                 | Oui           |                 |                  |
| [2.3&nbsp;SUIVI&nbsp;D'ACTION&nbsp;à&nbsp;j+20](https://app.mailjet.com/template/451123/build)                                                 | [action_suivi_j_20](https://app.mailjet.com/stats/campaigns-basic/6pH8Ik)          | [451123](https://app.mailjet.com/resource/template/451123/render) | Oui        | Oui        | (Oui)           | (Oui)   | (Oui)             | Oui             | Oui                 | (Oui)         |                 |                  |
| [2.4A&nbsp;Action&nbsp;Aboutie&nbsp;](https://app.mailjet.com/template/366621/build)                                                           | [action_aboutie](https://app.mailjet.com/stats/campaigns-basic/6pOZso)             | [366621](https://app.mailjet.com/resource/template/366621/render) | Oui        | Oui        | Oui             | (Oui)   | (Oui)             | Oui             | (Oui)               |               |                 |                  |
| [2.1.Event&nbsp;Confirmation&nbsp;créé&nbsp;à&nbsp;J0](https://app.mailjet.com/template/491291/build)                                          | [event_created_confirmation](https://app.mailjet.com/stats/campaigns-basic/6Gv8RE) | [491291](https://app.mailjet.com/resource/template/491291/render) | Oui        | Oui        | Oui             |         |                   | Oui             | Oui                 |               | Oui             | Oui              |
| [2.B.1&nbsp;EVENT&nbsp;Confirmation&nbsp;Participant&nbsp;J+0&nbsp;](https://app.mailjet.com/template/478397/build)                            | [event_joined_confirmation](https://app.mailjet.com/stats/campaigns-basic/6Gw2Cs)  | [478397](https://app.mailjet.com/resource/template/478397/render) | Oui        | Oui        | (Oui)           |         |                   | Oui             | Oui                 |               | Oui             | Oui              |
| [2.2.Event&nbsp;SUIVI&nbsp;Organisateur&nbsp;à&nbsp;J-1](https://app.mailjet.com/template/513115/build)                                        | [event_reminder_organizer](https://app.mailjet.com/stats/campaigns-basic/6GFOSO)   | [513115](https://app.mailjet.com/resource/template/513115/render) | Oui        | (Oui)      | Oui             |         |                   | Oui             | Oui                 | Oui           | Oui             | Oui              |
| [2.B.2.Event&nbsp;SUIVI&nbsp;Participant&nbsp;J-1](https://app.mailjet.com/template/491289/build)                                              | [event_reminder_participant](https://app.mailjet.com/stats/campaigns-basic/6GFOUk) | [491289](https://app.mailjet.com/resource/template/491289/render) | Oui        | (Oui)      | Oui             |         |                   | Oui             | Oui                 | Oui           | Oui             | Oui              |
| [2.3.Event&nbsp;SUIVI&nbsp;Organisateur&nbsp;à&nbsp;J+1](https://app.mailjet.com/template/491294/build)                                        | [event_followup_organizer](https://app.mailjet.com/stats/campaigns-basic/6H2z2S)   | [491294](https://app.mailjet.com/resource/template/491294/render) | Oui        | (Oui)      | Oui             |         |                   | Oui             |                     |               |                 |                  |
| [x.&nbsp;"Nouveau&nbsp;message&nbsp;:&nbsp;X&nbsp;vous&nbsp;envoie&nbsp;un&nbsp;message"&nbsp;](https://app.mailjet.com/template/604694/build) | [unread_reminder](https://app.mailjet.com/stats/campaigns-basic/6KX5W6)            | [604694](https://app.mailjet.com/resource/template/604694/render) | Oui        | Oui        | Oui             | (Oui)   | (Oui)             |                 |                     |               |                 |                  |
| [x.&nbsp;Recommandations&nbsp;Hebdo&nbsp;PROD&nbsp;Changement&nbsp;zone](https://app.mailjet.com/template/662271/build)                        | [digest_email](https://app.mailjet.com/stats/campaigns-basic/6KDzz2)               | [662271](https://app.mailjet.com/resource/template/662271/render) | Oui        | (Oui)      | Oui             | Oui     | (Oui)             |                 |                     |               |                 |                  |

(Oui) : variable disponible mais pas utilisée dans le template

### Variables uniques
#### 2.3 SUIVI D'ACTION à j+20 (action_suivi_j_20, 451123)

| action_success_url | action_support_url |
|--------------------|--------------------|
| Oui                | Oui                |

#### 2.4A Action Aboutie  (action_aboutie, 366621)

| volunteering_form_url |
|-----------------------|
| Oui                   |

#### 2.B.1 EVENT Confirmation Participant J+0  (event_joined_confirmation, 478397)

| event_json_ld | event_address_url |
|---------------|-------------------|
| Manquante     | Oui               |

#### x. "Nouveau message : X vous envoie un message"  (unread_reminder, 604694)

| nb_1 | nb_2 | group     | groups | subject | nb_1_text | nb_2_text | items_summary | author_summary |
|------|------|-----------|--------|---------|-----------|-----------|---------------|----------------|
| Oui  | Oui  | Manquante | Oui    | Oui     | Oui       | Oui       | Oui           | Oui            |

#### x. Recommandations Hebdo PROD Changement zone (digest_email, 662271)

| action    | actions | area_name | confirm_url |
|-----------|---------|-----------|-------------|
| Manquante | Oui     | Oui       | Oui         |

<!--generated:end-->

Note : ce tableau peut être généré automatiquement par `scripts/mailjet_doc.rb`
