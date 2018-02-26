#!/bin/bash

set -ex

CYAN='\033[0;36m'
NC='\033[0m' # No Color

cd ..

#rm -f ./../tasks/etf-validation-checker/ETF1.5.zip

echo -e "${CYAN}Building sandbox dashboard${NC}";
mvn clean install -Peea-inspire-dashboard -Drelax -DskipTests
echo -e "${CYAN}Building validator${NC}";
cd tasks/etf-validation-checker
mvn install -Drelax -DskipTests -Petf-download
cd ../../docker
docker-compose -f docker-compose-build.yml build sandbox-dashboard;
cd ..

echo -e "${CYAN}Building official dashboard${NC}";
mvn clean install -Peea-inspire-official -Drelax -DskipTests
echo -e "${CYAN}Building validator${NC}";
cd tasks/etf-validation-checker
mvn install -Drelax -DskipTests -Petf-download
cd ../../docker
docker-compose -f docker-compose-build.yml build official-dashboard;


echo -e "${CYAN}Building other images${NC}";
docker-compose -f docker-compose-build.yml build elasticsearch;
docker-compose -f docker-compose-build.yml build kibana;
docker-compose -f docker-compose-build.yml build nginx;
docker-compose -f docker-compose-build.yml build cerebro;
