#!/bin/bash
echo "=== ECS 503 Error Diagnostic ==="

CLUSTER="inventory-dashboard-dev-cluster"

# 1. Check ECR images
echo "1. ECR Images:"
aws ecr describe-images --repository-name inventory-dashboard-dev-backend --query 'imageDetails[0].imageTags' || echo "No backend images"
aws ecr describe-images --repository-name inventory-dashboard-dev-frontend --query 'imageDetails[0].imageTags' || echo "No frontend images"

# 2. Check ECS services
echo "2. ECS Services:"
aws ecs describe-services --cluster $CLUSTER --services inventory-dashboard-dev-backend inventory-dashboard-dev-frontend --query 'services[].{service:serviceName,desired:desiredCount,running:runningCount,pending:pendingCount,deployments:deployments[0].rolloutState}'

# 3. Check tasks
echo "3. Running Tasks:"
aws ecs list-tasks --cluster $CLUSTER --desired-status RUNNING --query 'taskArns[]'

# 4. Check stopped tasks for errors
echo "4. Stopped Tasks (Errors):"
aws ecs list-tasks --cluster $CLUSTER --desired-status STOPPED --query 'taskArns' --output text | tr '\t' '\n' | while read task; do
    if [ -n "$task" ]; then
        aws ecs describe-tasks --cluster $CLUSTER --tasks $task --query 'tasks[0].stoppedReason' --output text
    fi
done

# 5. Check target groups
echo "5. Target Group Health:"
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names inventory-dashboard-dev-backend --query 'TargetGroups[0].TargetGroupArn' --output text) --query 'TargetHealthDescriptions[].TargetHealth.State'
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names inventory-dashboard-dev-frontend --query 'TargetGroups[0].TargetGroupArn' --output text) --query 'TargetHealthDescriptions[].TargetHealth.State'

echo "=== Diagnostic Complete ==="