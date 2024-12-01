#!/bin/bash

# Validate AWS CLI installation or install if not present
if ! command -v aws &>/dev/null; then
    echo "AWS CLI is not installed. Installing AWS CLI..."
    sudo apt update -y
    sudo apt install -y unzip curl
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws

    if ! command -v aws &>/dev/null; then
        echo "Failed to install AWS CLI. Exiting."
        exit 1
    fi
    echo "AWS CLI installed successfully."
fi

# AWS Region and Instance Parameters
AWS_REGION="ap-northeast-3"  # Change to your desired region
AMI_ID="ami-05f4d8898209c4f55"  # Replace with the correct AMI ID for your region
INSTANCE_TYPE="t3.medium"
KEY_NAME="KiranM"  # Replace with your AWS Key Pair name
SECURITY_GROUP="sg-009b280c0ea3f798a"  # Replace with your Security Group ID
SUBNET_ID="subnet-0b4e5fded37cec9d4"  # Replace with your Subnet ID
INSTANCE_NAME="KiranM_EC2_Deployment"  # Remove space after '='

# Launch EC2 instance
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --region $AWS_REGION \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query "Instances[0].InstanceId" \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    echo "Failed to launch EC2 instance."
    exit 1
fi

echo "EC2 Instance ID: $INSTANCE_ID"

# Wait for instance initialization
echo "Waiting for instance to initialize..."
aws ec2 wait instance-running --region $AWS_REGION --instance-ids $INSTANCE_ID

# Get Public IP of the instance
INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

if [ -z "$INSTANCE_PUBLIC_IP" ]; then
    echo "Failed to retrieve Public IP."
    exit 1
fi

echo "EC2 Instance Public IP: $INSTANCE_PUBLIC_IP"

# SSH into the EC2 instance and deploy the application
echo "Deploying application to EC2 instance..."
ssh -o StrictHostKeyChecking=no -i "/path/to/$KEY_NAME.pem" ubuntu@$INSTANCE_PUBLIC_IP <<EOF
    # Update and install dependencies
    sudo apt update -y
    sudo apt install -y openjdk-8-jdk git maven

    # Clone the Vulnado repository

    git clone --branch develop https://github.com/mahalekiran/vulnado.git /home/ubuntu/vulnado
    cd /home/ubuntu/vulnado

    # Build the application
    mvn clean install

    # Run the application
    java -jar target/vulnado.jar &
EOF

echo "Application deployed successfully to EC2 instance: $INSTANCE_PUBLIC_IP"
