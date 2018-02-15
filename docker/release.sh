#!/bin/bash

# Should we update first?
#git pull

# Write githash into file
echo $(git ls-remote git://github.com/INSPIRE-MIF/daobs.git |    grep -v "refs/heads/2.0.x-security" | grep refs/heads/2.0.x | cut -f 1) > VERSION

# copy version to subdirs
cp VERSION ./cerebro/
cp VERSION ./kibana
cp VERSION ./elasticsearch/
cp VERSION ./nginx/

# bump version
version=`cat VERSION`
echo "version: $version"

# run build
./build_images.sh

docker tag inspiremif/daobs-eea-dashboard-sandbox:latest inspiremif/daobs-eea-dashboard-sandbox:$version
docker tag inspiremif/daobs-eea-dashboard-official:latest inspiremif/daobs-eea-dashboard-official:$version
docker tag inspiremif/elasticsearch:latest inspiremif/elasticsearch:$version
docker tag inspiremif/kibana:latest inspiremif/kibana:$version
docker tag inspiremif/nginx:latest inspiremif/nginx:$version
docker tag inspiremif/cerebro:latest inspiremif/cerebro:$version

# push it
#docker push inspiremif/daobs-eea-dashboard-sandbox:latest
#docker push inspiremif/daobs-eea-dashboard-sandbox:$version
#inspiremif/elasticsearch:latest
#inspiremif/elasticsearch:$version
#inspiremif/kibana:latest
#inspiremif/kibana:$version
#inspiremif/nginx:latest
#inspiremif/nginx:$version
#inspiremif/cerebro:latest
#inspiremif/cerebro:$version
