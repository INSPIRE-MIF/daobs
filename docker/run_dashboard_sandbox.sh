#!/bin/bash

docker-compose -p dashboard-sandbox -f docker-compose-canonical.yml -f docker-compose-eea-dashboard-sandbox.yml up -d
