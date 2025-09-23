#!/bin/bash
# Debug ECS services to find why containers aren't starting

echo "=== ECS Service Troubleshooting ==="
echo ""

# Check detailed service status
echo "1. Checking detailed service status..."
aws ecs describe-services \
  --cluster inventory-dashboard-dev-cluster \
  --services inventory-dashboard-dev-frontend inventory-dashboard-dev-backend \
  --query 'services[*].{Name:serviceName,Status:status,RunningCount:runningCount,PendingCount:pendingCount,DesiredCount:desiredCount,Events:events[0:3]}'

echo ""
echo "2. Checking task definitions..."
aws ecs describe-task-definition \
  --task-definition inventory-dashboard-dev-frontend \
  --query 'taskDefinition.{Family:family,Status:status,Revision:revision}'

aws ecs describe-task-definition \
  --task-definition inventory-dashboard-dev-backend \
  --query 'taskDefinition.{Family:family,Status:status,Revision:revision}'

echo ""
echo "3. Checking for failed tasks..."
aws ecs list-tasks \
  --cluster inventory-dashboard-dev-cluster \
  --desired-status STOPPED \
  --query 'taskArns[0:5]' \
  --output table

echo ""
echo "4. Getting details of recent stopped tasks..."
STOPPED_TASKS=$(aws ecs list-tasks --cluster inventory-dashboard-dev-cluster --desired-status STOPPED --query 'taskArns[0:2]' --output text)

if [ ! -z "$STOPPED_TASKS" ]; then
    echo "Recent stopped task details:"
    aws ecs describe-tasks \
      --cluster inventory-dashboard-dev-cluster \
      --tasks $STOPPED_TASKS \
      --query 'tasks[*].{TaskArn:taskArn,LastStatus:lastStatus,StoppedReason:stoppedReason,Containers:containers[*].{Name:name,ExitCode:exitCode,Reason:reason}}'
fi

echo ""
echo "5. Checking CloudWatch logs for errors..."
echo "Frontend logs:"
aws logs describe-log-streams \
  --log-group-name /ecs/inventory-dashboard-dev-frontend \
  --order-by LastEventTime \
  --descending \
  --max-items 3 \
  --query 'logStreams[*].{Name:logStreamName,LastEvent:lastEventTime}'

echo ""
echo "Backend logs:"
aws logs describe-log-streams \
  --log-group-name /ecs/inventory-dashboard-dev-backend \
  --order-by LastEventTime \
  --descending \
  --max-items 3 \
  --query 'logStreams[*].{Name:logStreamName,LastEvent:lastEventTime}'