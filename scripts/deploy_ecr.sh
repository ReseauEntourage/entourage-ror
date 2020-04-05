# Setup tools
pip3 install awscli # install aws cli w/o sudo
export PATH=$PATH:$HOME/.local/bin # put aws in the path

# Login to ECR on AWS (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are set as env vars)
eval $(aws ecr get-login --no-include-email --region eu-west-1)

# Reuse the image built during docker-compose up - just tag it and push it to the registry
docker tag entourage-ror:latest "494943233757.dkr.ecr.eu-west-1.amazonaws.com/entourage-ror:latest"
docker tag entourage-ror:latest "494943233757.dkr.ecr.eu-west-1.amazonaws.com/entourage-ror:$TRAVIS_JOB_ID"

docker push "494943233757.dkr.ecr.eu-west-1.amazonaws.com/entourage-ror:latest"
docker push "494943233757.dkr.ecr.eu-west-1.amazonaws.com/entourage-ror:$TRAVIS_JOB_ID"