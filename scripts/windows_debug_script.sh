#!/bin/bash
# Windows Git Bash compatible debug script

echo "=== Detailed Task Failure Analysis ==="
echo ""

# Get the specific failed task details
echo "1. Getting details of recent stopped tasks..."
STOPPED_TASKS=$(aws ecs list-tasks --cluster inventory-dashboard-dev-cluster --desired-status STOPPED --query 'taskArns[0:3]' --output text)

if [ ! -z "$STOPPED_TASKS" ] && [ "$STOPPED_TASKS" != "None" ]; then
    echo "Analyzing stopped tasks..."
    aws ecs describe-tasks \
      --cluster inventory-dashboard-dev-cluster \
      --tasks $STOPPED_TASKS \
      --query 'tasks[*].{TaskArn:taskArn,LastStatus:lastStatus,StoppedReason:stoppedReason,StoppedAt:stoppedAt,Containers:containers[*].{Name:name,ExitCode:exitCode,Reason:reason,LastStatus:lastStatus}}' \
      --output table
else
    echo "No stopped tasks found"
fi

echo ""
echo "2. Checking CloudWatch logs (Windows compatible)..."

# Use MSYS_NO_PATHCONV to prevent path conversion in Git Bash
export MSYS_NO_PATHCONV=1

echo "Frontend logs:"
aws logs describe-log-streams \
  --log-group-name "/ecs/inventory-dashboard-dev-frontend" \
  --order-by LastEventTime \
  --descending \
  --max-items 3 \
  --query 'logStreams[*].{Name:logStreamName,LastEvent:lastEventTime}' 2>/dev/null || echo "No frontend log streams found"

echo ""
echo "Backend logs:"
aws logs describe-log-streams \
  --log-group-name "/ecs/inventory-dashboard-dev-backend" \
  --order-by LastEventTime \
  --descending \
  --max-items 3 \
  --query 'logStreams[*].{Name:logStreamName,LastEvent:lastEventTime}' 2>/dev/null || echo "No backend log streams found"

echo ""
echo "3. Getting recent log events..."

# Get latest frontend logs
FRONTEND_STREAM=$(aws logs describe-log-streams --log-group-name "/ecs/inventory-dashboard-dev-frontend" --order-by LastEventTime --descending --max-items 1 --query 'logStreams[0].logStreamName' --output text 2>/dev/null)
if [ "$FRONTEND_STREAM" != "None" ] && [ ! -z "$FRONTEND_STREAM" ]; then
    echo "Recent frontend log events:"
    aws logs get-log-events \
      --log-group-name "/ecs/inventory-dashboard-dev-frontend" \
      --log-stream-name "$FRONTEND_STREAM" \
      --limit 20 \
      --query 'events[*].message' \
      --output text
else
    echo "No frontend logs available"
fi

echo ""
# Get latest backend logs
BACKEND_STREAM=$(aws logs describe-log-streams --log-group-name "/ecs/inventory-dashboard-dev-backend" --order-by LastEventTime --descending --max-items 1 --query 'logStreams[0].logStreamName' --output text 2>/dev/null)
if [ "$BACKEND_STREAM" != "None" ] && [ ! -z "$BACKEND_STREAM" ]; then
    echo "Recent backend log events:"
    aws logs get-log-events \
      --log-group-name "/ecs/inventory-dashboard-dev-backend" \
      --log-stream-name "$BACKEND_STREAM" \
      --limit 20 \
      --query 'events[*].message' \
      --output text
else
    echo "No backend logs available"
fi

echo ""
echo "4. Checking ECR repositories for images..."
echo "Frontend ECR images:"
aws ecr describe-images --repository-name inventory-dashboard-dev-frontend --query 'imageDetails[*].{Tags:imageTags,Pushed:imagePushedAt,Size:imageSizeInBytes}' --output table 2>/dev/null || echo "No images in frontend repository"

echo ""
echo "Backend ECR images:"
aws ecr describe-images --repository-name inventory-dashboard-dev-backend --query 'imageDetails[*].{Tags:imageTags,Pushed:imagePushedAt,Size:imageSizeInBytes}' --output table 2>/dev/null || echo "No images in backend repository"

echo ""
echo "5. Checking task definition details..."
aws ecs describe-task-definition --task-definition inventory-dashboard-dev-frontend --query 'taskDefinition.containerDefinitions[0].{Image:image,Memory:memory,Cpu:cpu,Essential:essential}' --output table

aws ecs describe-task-definition --task-definition inventory-dashboard-dev-backend --query 'taskDefinition.containerDefinitions[0].{Image:image,Memory:memory,Cpu:cpu,Essential:essential}' --output table