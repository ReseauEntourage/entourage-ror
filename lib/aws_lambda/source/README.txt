/************/
Deployment on AWS is done manually every time we update this repository


/************/
To do: more details


/************/
Avatars are uplpoaded to 300x300 by user
Lambda function copies file to source dir,
then resizes it to 300x300 pixels max in 300x300 dir,
then resizes it to 60x60 pixels max in 60x00 dir,


/************/
TO DEPLOY:

sls deploy -s dev
sls deploy -s staging
sls deploy -s prod


/************/
To touch existing files (already done! DO NOT DO IT AGAIN):


aws s3 cp --metadata {\"touched\":\"true\"}  s3://entourage-avatars-production-thumb/300x300/ s3://entourage-avatars-production-thumb/300x300/ --recursive
aws s3 cp --metadata {\"touched\":\"true\"}  s3://entourage-avatars-staging/users/300x300/testFPavatarEntourage.jpeg s3://entourage-avatars-staging/users/300x300/testFPavatarEntourage.jpeg

aws s3 cp s3://entourage-avatars-production-thumb/staging/source/ s3://entourage-avatars-staging/users/300x300/ --recursive

/************/
TO DO: record action into BDD
TO DO: handle PNG files for partner logo