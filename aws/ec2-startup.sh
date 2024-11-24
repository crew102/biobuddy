#!/bin/bash

set -e

apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    make \
    jq \
    unzip

echo -e "DOCKER INSTALL\n\n"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update && \
  apt-get install -y --no-install-recommends \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo -e "AWS CLI INSTALL\n\n"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

echo -e "CLONING REPO\n\n"
cd /home
git clone https://github.com/crew102/biobuddy.git
cd biobuddy
git checkout "$1"

# Reminder that we don't need aws credentials defined b/c EC2 is already told
# it has permissions to do what I need
echo -e "PULLING RELEVANT SECRETS\n\n"
declare -a secret_names=(
  "RSTUDIO_PASSWORD"
  "CR_PAT"
)
for secret_name in "${secret_names[@]}"; do

  to_export=$(
    aws secretsmanager get-secret-value --secret-id "$secret_name" \
      --query 'SecretString' --output text | \
      jq -r --arg KEY "$secret_name" \
      '. | to_entries | map(select(.key == $KEY)) | .[] | "\(.key)=\(.value)"'
  )

  export "$to_export"

done

echo -e "SETTING APP_IMAGE ENVVAR\n\n"
export APP_IMAGE="ghcr.io/crew102/bb-app":"$1"

echo -e "WRITING NGINX CONF FILE BASED ON IP ADDRESS AND CREATING ENV_FILES\n\n"
# To conform to local dev environment, though we won't end up using this file on
# EC2. On EC2 we source all of our secrets from AWS secrets store. The EC2
# instance was given secrets access and AWS propagates that access across all
# containers on EC2.
ENV_FILE=".Renviron"
touch "$ENV_FILE"

PROD="52.7.217.197"
STAGE="34.225.226.49"
LIP=$(curl ifconfig.me)
if [ "$LIP" == "$PROD" ]; then
  SERVER_NAME="biobuddyai.com"
  echo "ENVIRONMENT=prod" > "$ENV_FILE"
elif [ "$LIP" == "$STAGE" ]; then
  SERVER_NAME="biobuddydev.com"
  echo "ENVIRONMENT=staging" > "$ENV_FILE"
else
  echo "ERROR: IP address is not equal to either PROD or STAGE"
  exit 1
fi
# Needed for CRON, which on EC2 will have credentials but not region set:
echo "AWS_DEFAULT_REGION=us-east-1" >> "$ENV_FILE"
export SERVER_NAME
NEW_CONF_FILE=$(envsubst '${SERVER_NAME}' < services/nginx/nginx.conf)
echo "$NEW_CONF_FILE" > services/nginx/nginx.conf

echo -e "LISTING FILES\n\n"
ls -la

echo -e "PULLING BB-APP IMAGE\n\n"
echo "$CR_PAT" | docker login ghcr.io -u crew102 --password-stdin
if ! docker pull ghcr.io/crew102/bb-app:"$1"; then
  # For situations when in development and don't want to push current version of
  # image to CR
  echo -e "REVERTING TO USING LATEST IMAGE B/C LATEST
  COMMIT SHA ISN'T AVAILABLE\n\n"
  docker pull ghcr.io/crew102/bb-app:latest
fi

echo -e "RUNNING DOCKER-COMPOSE UP\n\n"
docker compose up -d

# For dev after running sudo su to change to root user:
echo "cd /home/biobuddy" >> ~/.bashrc
echo 'alias appimg="export APP_IMAGE=$(docker images --format \"{{.Repository}}:{{.Tag}}\" | grep bb-app)"' >> ~/.bashrc
echo 'alias portainer="appimg && docker compose restart portainer"' >> ~/.bashrc
echo 'alias prodtodev=cp -R /home/biobuddy/ /home/rstudio/ && chmod -R a+rwx  /home/rstudio/biobuddy' >> ~/.bashrc

echo -e "ONE-TIME INSTALL OF SSL CERT\n\n"
# Not terribly proud of this. Dipping into the nginx container and installing
# an SSL cert without a real plan for how to renew.
install_cert="/nginx/install-cert.sh"
nginx_container=$(docker compose ps -q nginx)
docker exec "$nginx_container" bash -c "export SERVER_NAME=\"$SERVER_NAME\"; chmod +x $install_cert; $install_cert"

echo -e "\n\nSTARTUP DONE\n\n"
