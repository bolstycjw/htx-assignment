#!/bin/bash
# This script should be run on the elastic-stack instance after terraform deploy
    
cd /home/ec2-user/app
    
# Clone your repository 
git clone https://github.com/bolstycjw/htx-assignment.git .
    
# Navigate to elastic-backend directory
cd elastic-backend
    
# Update docker-compose.yml volume paths
sed -i 's|elasticsearch-data-01:/usr/share/elasticsearch/data|/data/elasticsearch/data-01:/usr/share/elasticsearch/data|g' docker-compose.yml
sed -i 's|elasticsearch-data-02:/usr/share/elasticsearch/data|/data/elasticsearch/data-02:/usr/share/elasticsearch/data|g' docker-compose.yml
    
# Update Elasticsearch version if needed
sed -i 's|docker.elastic.co/elasticsearch/elasticsearch:.*|docker.elastic.co/elasticsearch/elasticsearch:8.17.4|g' docker-compose.yml
    
# Update Elasticsearch heap size
sed -i 's|ES_JAVA_OPTS=-Xms.*|ES_JAVA_OPTS=-Xms512m -Xmx512m|g' docker-compose.yml
    
# Start the Elasticsearch cluster and Kibana
docker-compose up -d
