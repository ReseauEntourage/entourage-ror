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
sls deploy -s prod
sls deploy -s pfp-dev
sls deploy -s pfp-prod

/************/
To touch existing files (already done! DO NOT DO IT AGAIN):

aws s3 cp --metadata {\"touched\":\"true\"}  s3://entourage-avatars-production-thumb/300x300/ s3://entourage-avatars-production-thumb/300x300/ --recursive
aws s3 cp --metadata {\"touched\":\"true\"}  s3://entourage-avatars-production-thumb/pfp/300x300/ s3://entourage-avatars-production-thumb/pfp/300x300/ --recursive
aws s3 cp --metadata {\"touched\":\"true\"}  s3://entourage-avatars-production-thumb/pfp/staging/300x300/ s3://entourage-avatars-production-thumb/pfp/staging/300x300/ --recursive


/************/
TO DO: remove aws-sdk from package.json (since it should already be on AWS server)
TO DO: record action into BDD