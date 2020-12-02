## Install, configure and start Elasticsearch

### Manual installation

Download Elasticsearch from https://www.elastic.co/fr/downloads/elasticsearch
and copy it to the ES module. eg. es/elasticsearch-5.2.1

Start ES.


### Maven installation

Maven could take care of the installation steps:
* download
* initialize collection
* start

Use the following commands:

```bash
cd es
mvn install -Pes-download
mvn exec:exec -Des-start
```

### Production use

Configure ES to start on server startup.
