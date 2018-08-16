## Install, configure and start Kibana

### Manual installation

Download Kibana from https://www.elastic.co/fr/downloads/kibana

Set the following properties in Kibana config (```config/kibana.yml```):
* base path 
* index name
* region map


```
server.basePath: "/<webappname>/dashboard"
server.rewriteBasePath: false

kibana.index: ".dashboards"

regionmap:
  layers:
     - name: "EU countries"
       url: "${webapp.rootUrl}assets/data/europe.geojson"
       attribution: "NaturalEarth"
       fields:
          - name: "NAME"
            description: "Full country name"
          - name: "ISO_A2"
            description: "ISO 2 letters code"
          - name: "ISO_A3"
            description: "ISO 3 letters code"
            
```

Adapt if needed ```elasticsearch.url``` and ```server.host```.

Start Kibana. Kibana should be running from:

```
http://localhost:5601

```

If not starting properly, check Kibana log file (eg. may fail if Elasticsearch version
is not compatible with Kibana version).


Start Kibana manually:

```
cd kibana/bin
./kibana
```

Import dashboard configuration:

```
npm install elasticdump -g

cd resources/data
elasticdump \
  --input=index-dashboards-mapping.json \
  --output=http://admin:admin@localhost:9200/.dashboards \
  --type=mapping \
  -headers='{"Content-Type": "application/json"}'

elasticdump \
  --input=index-dashboards.json \
  --output=http://admin:admin@localhost:9200/.dashboards \
  -headers='{"Content-Type": "application/json"}' 

```


### Maven installation

Maven could take care of the installation steps:
* download
* configure Kibana
* start

Use the following commands:

```
cd dashboards
mvn install -Pkb-download
mvn exec:exec -Dkb-start
```

### Production use

Configure Kibana to start on server startup.


### Backup index

```
npm install elasticdump -g

cd resources/data
rm index-dashboards-mapping.json index-dashboards.json
elasticdump \
  --input=http://localhost:9200/.dashboards \
  --output=index-dashboards-mapping.json \
  --type=mapping

elasticdump \
  --input=http://localhost:9200/.dashboards \
  --output=index-dashboards.json  
```
