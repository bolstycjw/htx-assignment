# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EBS Volume for Elasticsearch
resource "aws_ebs_volume" "elastic_data" {
  availability_zone = aws_subnet.public.availability_zone
  size              = var.elastic_ebs_size
  type              = "gp2"

  tags = {
    Name = "${local.project_name}-elastic-data"
  }
}

# EC2 Instance for Elastic Stack (Host 1)
resource "aws_instance" "elastic_stack" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.elasticsearch.id,
    aws_security_group.kibana.id,
    aws_security_group.docker_network.id
  ]
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch.name

  root_block_device {
    volume_size = 8 # Default size for root volume
    volume_type = "gp2"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install Docker
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Install Git and other utilities
    yum install -y git jq
    
    # Configure system for Elasticsearch
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf
    
    # Wait for EBS volume to be attached
    until lsblk | grep -q xvdf; do
      echo "Waiting for EBS volume to be attached..."
      sleep 5
    done
    
    # Format and mount the EBS volume
    mkfs -t xfs /dev/xvdf
    mkdir -p /data/elasticsearch
    mount /dev/xvdf /data/elasticsearch
    chown -R ec2-user:ec2-user /data/elasticsearch
    
    # Add mount point to fstab for persistence across reboots
    echo "/dev/xvdf /data/elasticsearch xfs defaults,nofail 0 2" | tee -a /etc/fstab
    
    # Create directory for Elasticsearch data
    mkdir -p /data/elasticsearch/data-01
    mkdir -p /data/elasticsearch/data-02
    chown -R ec2-user:ec2-user /data/elasticsearch
    
    # Create application directory
    mkdir -p /home/ec2-user/app
    chown -R ec2-user:ec2-user /home/ec2-user/app
  EOF

  tags = {
    Name = "${local.project_name}-elastic-stack"
  }
}

# Attach EBS volume to elastic-stack instance
resource "aws_volume_attachment" "elastic_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.elastic_data.id
  instance_id = aws_instance.elastic_stack.id
}

# EC2 Instance for Search UI (Host 2)
resource "aws_instance" "services" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.ui.id,
    aws_security_group.docker_network.id
  ]
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch.name

  root_block_device {
    volume_size = 8 # Default size for root volume
    volume_type = "gp2"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install Docker
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Install Git and other utilities
    yum install -y git jq
    
    # Create application directory
    mkdir -p /home/ec2-user/app
    chown -R ec2-user:ec2-user /home/ec2-user/app
    
    # Create docker network
    docker network create elastic-network
  EOF

  tags = {
    Name = "${local.project_name}-ui-services"
  }
}

# EC2 Instance for ASR API (Host 3)
resource "aws_instance" "asr" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.asr.id,
    aws_security_group.docker_network.id
  ]
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch.name

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y
    
    # Install Docker
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Install Git and other utilities
    yum install -y git jq
    
    # Create upload directory
    mkdir -p /tmp/uploads
    chmod 777 /tmp/uploads
    
    # Create application directory
    mkdir -p /home/ec2-user/app
    chown -R ec2-user:ec2-user /home/ec2-user/app
    
    # Create docker network
    docker network create elastic-network
  EOF

  tags = {
    Name = "${local.project_name}-asr-api"
  }
}

# Create templates for user-data customization
resource "local_file" "elastic_stack_setup" {
  content = <<-EOF
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
    sed -i 's|docker.elastic.co/elasticsearch/elasticsearch:.*|docker.elastic.co/elasticsearch/elasticsearch:${var.elasticsearch_version}|g' docker-compose.yml
    
    # Update Elasticsearch heap size
    sed -i 's|ES_JAVA_OPTS=-Xms.*|ES_JAVA_OPTS=-Xms${var.elasticsearch_heap_size}m -Xmx${var.elasticsearch_heap_size}m|g' docker-compose.yml
    
    # Start the Elasticsearch cluster and Kibana
    docker-compose up -d
  EOF

  filename = "${path.module}/elastic_stack_setup.sh"
}

resource "local_file" "services_setup" {
  content = <<-EOF
    #!/bin/bash
    # This script should be run on the services instance after terraform deploy
    
    cd /home/ec2-user/app
    
    # Clone your repository
    git clone https://github.com/bolstycjw/htx-assignment.git .
    
    # Navigate to search-ui directory
    cd search-ui
    
    # Create environment file for Search UI
    cat > .env << EOL
    ELASTICSEARCH_HOST=http://${aws_instance.elastic_stack.public_ip}:9200
    ELASTICSEARCH_INDEX=cv-transcriptions
    EOL
    
    # Start the Search UI
    docker-compose up -d
  EOF

  filename = "${path.module}/services_setup.sh"
}

resource "local_file" "asr_setup" {
  content = <<-EOF
    #!/bin/bash
    # This script should be run on the ASR API instance after terraform deploy
    
    cd /home/ec2-user/app
    
    # Clone your repository
    git clone https://github.com/bolstycjw/htx-assignment.git .
    
    # Navigate to ASR API directory
    cd asr
    
    # Start the ASR API
    docker-compose up -d
  EOF

  filename = "${path.module}/asr_setup.sh"
} 
