#!/bin/bash

certbot --nginx \
  -d ${SERVER_NAME} \
  -d www.${SERVER_NAME} \
  --non-interactive \
  --agree-tos \
  --email chriscrewbaker@gmail.com
