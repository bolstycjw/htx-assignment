#!/bin/bash
# This script should be run on the services instance after terraform deploy
    
cd /home/ec2-user/app
    
# Clone your repository
git clone https://github.com/bolstycjw/htx-assignment.git .
    
# Navigate to search-ui directory
cd search-ui
    
# Create environment file for Search UI
cat > .env << EOL
ELASTICSEARCH_HOST=http://18.142.126.205:9200
ELASTICSEARCH_INDEX=cv-transcriptions
EOL
    
# Start the Search UI
docker-compose up -d
