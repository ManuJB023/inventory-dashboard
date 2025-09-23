#!/bin/bash
echo "=== Manual Infrastructure Cleanup ==="

# Set variables
CLUSTER="inventory-dashboard-dev-cluster"
SERVICES=("inventory-dashboard-dev-backend" "inventory-dashboard-dev-frontend")
REPOS=("inventory-dashboard-dev-backend" "inventory-dashboard-dev-frontend")
DB_INSTANCE="inventory-dashboard-dev-postgres"

echo "1. Stopping and deleting ECS Services..."
for service in "${SERVICES[@]}"; do
    echo "Stopping service: $service"
    aws ecs update-service --cluster $CLUSTER --service $service --desired-count 0
    sleep 10
    aws ecs delete-service --cluster $CLUSTER --service $service --force
    sleep 10
done

echo "2. Deleting ECS Cluster..."
aws ecs delete-cluster --cluster $CLUSTER

echo "3. Deleting RDS Database Instance..."
aws rds delete-db-instance \
    --db-instance-identifier $DB_INSTANCE \
    --skip-final-snapshot \
    --delete-automated-backups

echo "4. Waiting for RDS deletion to start (30 seconds)..."
sleep 30

echo "5. Deleting RDS Subnet Group..."
aws rds delete-db-subnet-group --db-subnet-group-name inventory-dashboard-dev-db-subnet-group

echo "6. Cleaning up ECR Repositories..."
for repo in "${REPOS[@]}"; do
    echo "Deleting images in repository: $repo"
    
    # List all image digests
    IMAGES=$(aws ecr list-images --repository-name $repo --query 'imageIds[].imageDigest' --output text)
    
    if [ -n "$IMAGES" ]; then
        # Delete all images
        for image in $IMAGES; do
            aws ecr batch-delete-image --repository-name $repo --image-ids imageDigest=$image
        done
    fi
    
    # Force delete the repository
    echo "Force deleting repository: $repo"
    aws ecr delete-repository --repository-name $repo --force
done

echo "7. Deleting Load Balancer..."
aws elbv2 delete-load-balancer --load-balancer-arn $(aws elbv2 describe-load-balancers --names inventory-dashboard-dev-lb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "8. Deleting Target Groups..."
aws elbv2 delete-target-group --target-group-arn $(aws elbv2 describe-target-groups --names inventory-dashboard-dev-backend --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 delete-target-group --target-group-arn $(aws elbv2 describe-target-groups --names inventory-dashboard-dev-frontend --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "9. Deleting CloudWatch Log Groups..."
aws logs delete-log-group --log-group-name "/ecs/inventory-dashboard-dev-backend"
aws logs delete-log-group --log-group-name "/ecs/inventory-dashboard-dev-frontend"

echo "10. Deleting SSM Parameters..."
aws ssm delete-parameter --name "/inventory-dashboard-dev/db/host"
aws ssm delete-parameter --name "/inventory-dashboard-dev/db/user"
aws ssm delete-parameter --name "/inventory-dashboard-dev/db/password"
aws ssm delete-parameter --name "/inventory-dashboard-dev/jwt/secret"

echo "11. Cleaning up Network Resources (if no other dependencies)..."
# Note: Be careful with VPC deletion - might have other resources
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=inventory-dashboard-dev-vpc" --query 'Vpcs[0].VpcId' --output text)

if [ -n "$VPC_ID" ]; then
    echo "VPC ID: $VPC_ID"
    echo "Warning: VPC deletion will remove all networking resources. Continue? (y/n)"
    read -r response
    if [ "$response" = "y" ]; then
        # Delete internet gateway
        IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
        if [ -n "$IGW_ID" ]; then
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
            aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
        fi
        
        # Delete subnets
        aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].SubnetId' --output text | tr '\t' '\n' | while read subnet; do
            aws ec2 delete-subnet --subnet-id $subnet
        done
        
        # Delete route tables (except main)
        aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | tr '\t' '\n' | while read rt; do
            aws ec2 delete-route-table --route-table-id $rt
        done
        
        # Delete security groups (except default)
        aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | tr '\t' '\n' | while read sg; do
            aws ec2 delete-security-group --group-id $sg
        done
        
        # Delete VPC
        aws ec2 delete-vpc --vpc-id $VPC_ID
    fi
fi

echo "=== Cleanup complete! ==="