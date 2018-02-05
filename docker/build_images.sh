#!/bin/bash

CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Building wars${NC}";
cd ..

rm ./tasks/etf-validation-checker/ETF1.5.zip

mvn clean install -Peea-inspire-dashboard -Drelax -DskipTests
mvn clean install -Peea-inspire-official -Drelax -DskipTests

echo -e "${CYAN}Building validator${NC}";
cd tasks/etf-validation-checker
mvn install -Drelax -DskipTests -Petf-download

echo -e "${CYAN}Building images${NC}";
cd ../../docker
docker-compose -f docker-compose-build.yml build
