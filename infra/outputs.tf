output "elastic_stack_public_ip" {
  description = "Public IP address of the Elastic Stack instance"
  value       = aws_eip.elastic_stack.public_ip
}

output "elastic_stack_private_ip" {
  description = "Private IP address of the Elastic Stack instance"
  value       = aws_instance.elastic_stack.private_ip
}

output "services_public_ip" {
  description = "Public IP address of the Services instance"
  value       = aws_eip.services.public_ip
}

output "asr_public_ip" {
  description = "Public IP address of the ASR API instance"
  value       = aws_eip.asr.public_ip
}

output "elasticsearch_url" {
  description = "URL to access Elasticsearch"
  value       = "http://${aws_eip.elastic_stack.public_ip}:9200"
}

output "kibana_url" {
  description = "URL to access Kibana"
  value       = "http://${aws_eip.elastic_stack.public_ip}:5601"
}

output "search_ui_url" {
  description = "URL to access Search UI"
  value       = "http://${aws_eip.services.public_ip}:3000"
}

output "asr_api_url" {
  description = "URL to access ASR API"
  value       = "http://${aws_eip.asr.public_ip}:8001"
}

output "setup_instructions" {
  description = "Post-deployment setup instructions"
  value       = <<-EOF
    =====================================================================
    DEPLOYMENT COMPLETED SUCCESSFULLY!
    =====================================================================
    
    Follow these steps to complete the setup:
    
    1. SSH to the Elastic Stack instance:
       ssh -i <your-key.pem> ec2-user@${aws_eip.elastic_stack.public_ip}
    
    2. Run the Elastic Stack setup script:
       First, copy the generated script to the instance:
       scp -i <your-key.pem> ${path.module}/elastic_stack_setup.sh ec2-user@${aws_eip.elastic_stack.public_ip}:~
       
       Then SSH to the instance and run:
       chmod +x ~/elastic_stack_setup.sh
       ./elastic_stack_setup.sh
    
    3. SSH to the Services instance:
       ssh -i <your-key.pem> ec2-user@${aws_eip.services.public_ip}
    
    4. Run the Services setup script:
       First, copy the generated script to the instance:
       scp -i <your-key.pem> ${path.module}/services_setup.sh ec2-user@${aws_eip.services.public_ip}:~
       
       Then SSH to the instance and run:
       chmod +x ~/services_setup.sh
       ./services_setup.sh
    
    5. SSH to the ASR API instance:
       ssh -i <your-key.pem> ec2-user@${aws_eip.asr.public_ip}
    
    6. Run the ASR API setup script:
       First, copy the generated script to the instance:
       scp -i <your-key.pem> ${path.module}/asr_setup.sh ec2-user@${aws_eip.asr.public_ip}:~
       
       Then SSH to the instance and run:
       chmod +x ~/asr_setup.sh
       ./asr_setup.sh
    
    =====================================================================
    ACCESS POINTS:
    =====================================================================
    
    Elasticsearch: ${aws_eip.elastic_stack.public_ip}:9200
    Kibana:        ${aws_eip.elastic_stack.public_ip}:5601
    Search UI:     ${aws_eip.services.public_ip}:3000
    ASR API:       ${aws_eip.asr.public_ip}:8001
    
    =====================================================================
  EOF
} 