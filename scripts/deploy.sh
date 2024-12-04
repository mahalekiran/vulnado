#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# AWS Region and Instance Parameters
AWS_REGION="ap-northeast-3"
AMI_ID="ami-05f4d8898209c4f55" 
INSTANCE_TYPE="t3.medium"
KEY_NAME="KiranM" 
SECURITY_GROUP="sg-009b280c0ea3f798a"
SUBNET_ID="subnet-0b4e5fded37cec9d4"
INSTANCE_NAME="KiranM_EC2_Deployment"


# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --region $AWS_REGION \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --query "Instances[0].InstanceId" \
    --output text)


echo "EC2 Instance ID: $INSTANCE_ID"

echo "Waiting for EC2 instance to initialize..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get Public IP
INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)


echo "EC2 Instance Public IP: $INSTANCE_PUBLIC_IP"

# SSH into the EC2 instance and deploy the application
echo "Deploying application to EC2 instance..."
ssh -o StrictHostKeyChecking=no -i "/path/to/$KEY_NAME.pem" ubuntu@$INSTANCE_PUBLIC_IP <<EOF
    # Update and install dependencies
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y openjdk-8-jdk git maven

    # Clone the Vulnado repository and checkout the 'develop' branch
    git clone --branch develop https://github.com/mahalekiran/vulnado.git /home/ubuntu/vulnado
    cd /home/ubuntu/vulnado

    # Build the application
    mvn clean install

    # Run the application
    java -jar target/vulnado.jar &
EOF

echo "Application deployed successfully to EC2 instance: $INSTANCE_PUBLIC_IP"