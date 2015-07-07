FORMAT: 1A

# Entourage
Entourage application backend API documentation.

# Group Map
Map related resources of the **Entourage API**

## Map collection [/map.json{?token,limit,latitude,longitude,distance}]
A single Note object with all its details

+ Parameters
    + token (required, string, `aaabbbcccddd`) ... Token identifying the current user
    + limit (optional, number, `15`) ... Max number of pois to return. 45 if not defined
    + latitude (optional, number, `42`) ... Latitude of middle point of the square (for geolocated results)
    + longitude (optional, number, `2`) ... Latitude of middle point of the square (for geolocated results)
    + distance (optional, number, `1`) ... Half side of the result square (for geolocated results)

### Get all map points [GET]

+ Response 200 (application/json)

    + Body

            {"categories":[
            {"id":1,"name":"Se nourrir"},{"id":2,"name":"Se loger"},{"id":3,"name":"Se soigner"},{"id":4,"name":"Se rafraîchir"},{"id":5,"name":"S'orienter"},{"id":6,"name":"S'occuper de soi"},{"id":7,"name":"Se réinsérer"},{"id":8,"name":"Test"}],
            "pois":[
            {"id":3,"name":"SSDP","description":"Services sociaux départementaux polyvalents (SSDP) :\r\nOuverture du lundi au vendredi 8h30h-17h.","longitude":2.320442,"latitude":48.857464,"adress":"116, rue de Grenelle, 75007","phone":"01 53 58 77 25","website":"","email":"","audience":"","category_id":5},
            {"id":4,"name":"CASVP","description":"Sections du Centre d’action sociale (CASVP) : \r\nOuverture du lundi au vendredi 8h30-17h.","longitude":2.320442,"latitude":48.857464,"adress":"116, rue de Grenelle, 75007","phone":"01 53 58 77 16","website":"","email":"","audience":"","category_id":5},
            {"id":5,"name":"LES CAMIONS DES RESTOS DU COEUR Invalides","description":"Distribution de repas chauds MARDI,JEUDI,SAMEDI à partir de 20h,DIMANCHE à partir de 19h30\r\n","longitude":2.31161,"latitude":48.861876,"adress":"9, rue Fabert, 75007","phone":"","website":"","email":"","audience":"Sans inscription et sans conditions de ressources","category_id":1}],
            "encounters":[
            {"id":81,"date":"2014-10-13T21:12:00.000+02:00","latitude":48.851811,"longitude":2.335968,"user_id":4,"user_name":"Romain","street_person_name":"Pablo","message":"Voici le beau message audio de Pablo : http://youtu.be/f5-9ew-Rw3s","voice_message":"http://youtu.be/f5-9ew-Rw3s"},
            {"id":68,"date":"2014-10-11T18:51:15.000+02:00","latitude":48.8712568125142,"longitude":2.33136908565056,"user_id":1,"user_name":"Entourage","street_person_name":"Michel","message":"La vie est belle","voice_message":null}]
            }
            
+ Response 401 (application/json)

        {"error":{"status":401,"message":"Please sign-in"}}

# Group Encounters
Encounters related resources of the **Entourage API**

## Encounters collection [/encounters.json{?token}]

+ Parameters
    + token (required, string, `aaabbbcccddd`) ... Token identifying the current user

### Create an Encounter [POST]

+ Request (application/json)
    
        {"encounter":{"street_person_name":"jean","date":"2014-10-11 15:19:45","latitude":42,"longitude":2,"message":"test","voice_message":"http://www.google.com"}}

+ Response 200 (application/json)

        {"encounter":{"id":1,"date":"2014-10-11T15:19:45.000+02:00","latitude":42.0,"longitude":2.0,"user_id":1,"user_name":"Eric","street_person_name":"jean","message":"test","voice_message":"http://www.google.com"}}
        
+ Response 400 (application/json)

        {"error":{"status":400,"message":"Could not create encouter","reasons":["Date can't be blank","Street person name can't be blank","Latitude can't be blank","Latitude is not a number","Longitude can't be blank","Longitude is not a number"]}}

+ Response 401 (application/json)

        {"error":{"status":401,"message":"Please sign-in"}}

# Group POIs
POI related resources of the **Entourage API**

## Pois collection [/pois.json{?token}]

+ Parameters
    + token (required, string, `aaabbbcccddd`) ... Token identifying the current user

### List all POIs [GET]

+ Response 200 (application/json)

        {categories: [{id: 1,name: "Se nourrir"},{id: 2,name: "Se loger"},{id: 3,name: "Se soigner"},{id: 4,name: "Se rafraîchir"},{id: 5,name: "S'orienter"},{id: 6,name: "S'occuper de soi"},{id: 7,name: "Se réinsérer"}],
        pois: [
        {id: 3,name: "SSDP",description: "Services sociaux départementaux polyvalents (SSDP) : Ouverture du lundi au vendredi 8h30h-17h. ",longitude: 2.320442,latitude: 48.857464,adress: "116, rue de Grenelle, 75007",phone: "01 53 58 77 25",website: "",email: "",audience: "",category_id: 5},
        {id: 5,name: "LES CAMIONS DES RESTOS DU COEUR Invalides",description: "Distribution de repas chauds MARDI,JEUDI,SAMEDI à partir de 20h,DIMANCHE à partir de 19h30 ",longitude: 2.31161,latitude: 48.861876,adress: "9, rue Fabert, 75007",phone: "",website: "",email: "",audience: "Sans inscription et sans conditions de ressources",category_id: 1},
        {id: 6,name: "EAU POTABLE",description: "Dans Paris, il existe de très nombreuses fontaines distribuant de l’eau potable, une eau strictement identique à celle distribuée dans les appartements, que vous pouvez consommer sans réticence.",longitude: 2.31149,latitude: 48.861149,adress: "136, rue de l’Université,angle rue Fabert, 75007",phone: "",website: "",email: "",audience: "",category_id: 1}
        ]}

+ Response 401 (application/json)

        {"error":{"status":401,"message":"Please sign-in"}}

# Group Users

Users related resources of the **Entourage API**

## User actions [/login.json]

### Login user [POST]

+ Request

    + Header
            
            Content-type: application/x-www-form-urlencoded; charset=utf-8
    
    + Body
    
            email=user@email.com


+ Response 200 (application/json)

        {"user":{"id":20,"email":"user@email.com","first_name":"Jean","last_name":"Test","token":"aaabbbcccddd"}}

+ Response 400 (application/json)

        {"error":{"status":400,"message":"Login failed"}}

# Group Newsletter

Newsletter subscription related resources of the **Entourage API**

## Newsletter actions [/newsletter_subscription.json]

### Create new subscription [POST]

+ Request (application/json)
    
        {"newsletter_subscription":{"email":"newslette@subscription.com","active":true}}

+ Response 200
        
+ Response 400



# Group Tours
Tours related resources of the **Entourage API**

## Tours collection [/tours{?token}]

+ Parameters
    + token (required, string, `aaabbbcccddd`) ... Token identifying the current user
    + tour_type (required, string, `social`) ... Type of the tour. Must be within ["social", "food", "other"]

### Create an Encounter [POST]

+ Request (application/json)
    
        {"tour":{"tour_type":"social"}}

+ Response 200 (application/json)

        {"tour":{"id":1,"type":"social"}}
        
+ Response 400 (application/json)

        {"error":{"status":400,"message":"Could not create tour","reasons":["Tour type is not included in the list"]}}

+ Response 401 (application/json)

        {"error":{"status":401,"message":"Please sign-in"}}

