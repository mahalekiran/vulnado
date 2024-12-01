#!/bin/bash

# AWS Region and Instance Parameters
AWS_REGION="ap-northeast-3"  # Change to your desired region
AMI_ID="ami-05f4d8898209c4f55"  # Replace with the correct AMI ID for your region
INSTANCE_TYPE="t3.medium"
KEY_NAME="KiranM"  # Replace with your AWS Key Pair name
SECURITY_GROUP="sg-009b280c0ea3f798a"  # Replace with your Security Group ID
SUBNET_ID="subnet-0b4e5fded37cec9d4"  # Replace with your Subnet ID
INSTANCE_NAME= "KiranM_EC2_Deployment"

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --region $AWS_REGION \
    --tag "Key=Name,Value=$INSTANCE_NAME" \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --query "Instances[0].InstanceId" \
    --output text)

echo "EC2 Instance ID: $INSTANCE_ID"

# Wait for the instance to initialize and then get its public IP
INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
    --region $AWS_REGION \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo "EC2 Instance Public IP: $INSTANCE_PUBLIC_IP"

withCredentials([sshUserPrivateKey(credentialsId: "$SSH_KEY_ID", keyFileVariable: 'SSH_KEY')]) {
    sh '''
    # SSH into the EC2 instance and deploy the app
    ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$INSTANCE_PUBLIC_IP << 'EOF'

        # Update and install necessary software
        sudo yum update -y
        sudo yum install -y java-1.8.0-openjdk git

        # Install Maven for Java build
        sudo yum install -y maven

        # Clone your Vulnado repository (or use SCP to upload files)
        git clone https://github.com/mahalekiran/vulnado.git /home/ubuntu/vulnado
        cd /home/ubuntu/vulnado
        mvn clean install

        # java application
        java -jar target/vulnado.jar
    EOF
    '''
}

echo "Application deployed successfully on EC2 instance: $INSTANCE_PUBLIC_IP"