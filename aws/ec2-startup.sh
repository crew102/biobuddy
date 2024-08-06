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

echo -e "WRITING SECRETS FILE\n\n"
declare -a secret_names=(
  "PF_CLIENT_ID"
  "PF_CLIENT_SECRET"
  "OPENAI_API_KEY"
  "POLISHED_API_KEY"
  "FIREBASE_API_KEY"
  "RSTUDIO_PASSWORD"
  "CR_PAT"
)
for secret_name in "${secret_names[@]}"; do

  secret_value=$(
    aws secretsmanager get-secret-value --secret-id "$secret_name" \
      --query 'SecretString' --output text | \
      jq -r --arg KEY "$secret_name" \
      '. | to_entries | map(select(.key == $KEY)) | .[] | "\(.key)=\(.value)"'
  )

  # Includes the name of the secret (i..e, SOME_SECRET=hithere)
  echo "$secret_value" >> "secrets.txt"

  if [ "$secret_name" == "CR_PAT" ]; then
    export "$secret_value"
  fi

done

echo -e "WRITING .ENV FILE\n\n"
# Set rstudio password using docker compose env vars interpolation
grep RSTUDIO_PASSWORD secrets.txt > .env

echo -e "WRITING NGINX CONF FILE BASED ON IP ADDRESS\n\n"
PROD="52.7.217.197"
STAGE="34.225.226.49"
LIP=$(curl ifconfig.me)
if [ "$LIP" == "$PROD" ]; then
  SERVER_NAME="biobuddyai.com"
elif [ "$LIP" == "$STAGE" ]; then
  SERVER_NAME="biobuddydev.com"
else
  echo "ERROR: IP address is not equal to either PROD or STAGE"
  exit 1
fi
export SERVER_NAME
NEW_CONF_FILE=$(envsubst '${SERVER_NAME}' < services/nginx/nginx.conf)
echo "$NEW_CONF_FILE" > services/nginx/nginx.conf

echo -e "PULLING BB-APP IMAGE\n\n"
echo "$CR_PAT" | docker login ghcr.io -u crew102 --password-stdin
docker pull ghcr.io/crew102/bb-app:latest

echo -e "RUNNING DOCKER-COMPOSE UP\n\n"
make bup

echo -e "ONE-TIME INSTALL OF SSL CERT\n\n"
# Not terribly proud of this. Dipping into the nginx container and installing
# an SSL cert without a real plan for how to renew.
install_cert="/nginx/install-cert.sh"
nginx_container=$(docker compose ps -q nginx)
docker exec "$nginx_container" bash -c "export $SERVER_NAME; chmod +x $install_cert; $install_cert"

echo "cd /home/biobuddy" >> ~/.bashrc

echo -e "\n\nSTARTUP DONE\n\n"
