#/bin/bash

# Replace admin password
cp /users.properties /daobs-data-dir/datadir/users.properties;
sed "s#ADMINPASSWORD#$ADMINPASSWORD#g" -i /daobs-data-dir/datadir/users.properties

cd /daobs-data-dir/datadir/;

echo "Checking if index already exists:"
STATUS=$(curl -IHEAD --write-out %{http_code} --silent --output /dev/null 'elasticsearch:9200/.dashboards')
echo $STATUS

if [ $STATUS = 404 ]; then

  echo "Index does not exists: creating"

  elasticdump \
    --input=index-dashboards-mapping.json \
    --output=http://admin:$ADMINPASSWORD@elasticsearch:9200/.dashboards \
    --type=mapping \
    -headers='{"Content-Type": "application/json"}'

  elasticdump \
    --input=index-dashboards.json \
    --output=http://admin:$ADMINPASSWORD@elasticsearch:9200/.dashboards \
    -headers='{"Content-Type": "application/json"}'

elif [ $STATUS = 200 ]; then

  echo "Index already exists; skipping"

else
  echo "Something else"
fi

echo -e "\e[96mStart tomcat\e[0m"

cd $CATALINA_HOME
catalina.sh run
