#!/bin/bash
# This script should be run on the ASR API instance after terraform deploy
    
cd /home/ec2-user/app
    
# Clone your repository
git clone https://github.com/bolstycjw/htx-assignment.git .
    
# Navigate to ASR API directory
cd asr
    
# Start the ASR API
docker-compose up -d
