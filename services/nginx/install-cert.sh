#!/bin/bash

certbot --nginx \
  -d biobuddydev.com \
  -d www.biobuddydev.com \
  --non-interactive \
  --agree-tos \
  --email chriscrewbaker@gmail.com
