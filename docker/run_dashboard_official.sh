#!/bin/bash

docker-compose -p dashboard-official -f docker-compose-canonical.yml -f docker-compose-eea-dashboard-official.yml up -d
