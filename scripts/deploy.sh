#!/bin/bash

# scripts/deploy.sh
# Enhanced deployment script for inventory dashboard

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAME="inventory-dashboard"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Docker registry configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
DOCKER_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
BACKEND_IMAGE="${DOCKER_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-backend"
FRONTEND_IMAGE="${DOCKER_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG:${NC} $1"
}

# Print usage information
print_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  infra     Deploy infrastructure (VPC, ECS, RDS, etc.)"
    echo "  images    Build and push Docker images"
    echo "  services  Deploy/update ECS services"
    echo "  migrate   Run database migrations"
    echo "  rollback  Rollback to previous version"
    echo "  destroy   Destroy all infrastructure"
    echo "  status    Check deployment status"
    echo "  logs      Show application logs"
    echo "  shell     Connect to running container"
    echo ""
    echo "Environment Variables:"
    echo "  ENVIRONMENT    Deployment environment (dev/staging/prod)"
    echo "  AWS_REGION     AWS region (default: us-east-1)"
    echo "  IMAGE_TAG      Docker image tag (default: latest)"
    echo ""
    echo "Examples:"
    echo "  ENVIRONMENT=dev ./scripts/deploy.sh infra"
    echo "  ENVIRONMENT=prod IMAGE_TAG=v1.2.3 ./scripts/deploy.sh services"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required commands
    local required_commands=("aws" "terraform" "docker" "jq")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "$cmd is required but not installed"
            exit 1
        fi
    done
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "terraform/main.tf" ]; then
        log_error "terraform/main.tf not found. Please run from project root."
        exit 1
    fi
    
    log_info "All prerequisites satisfied"
}

# Initialize Terraform with proper backend handling
init_terraform() {
    log_info "Initializing Terraform..."
    
    # Check if backend config needs migration
    if terraform init -backend-config="key=${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate" 2>&1 | grep -q "Backend configuration changed"; then
        log_warn "Backend configuration changed. Performing state migration..."
        terraform init -migrate-state -backend-config="key=${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate"
    else
        terraform init -backend-config="key=${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate"
    fi
    
    # Create workspace if it doesn't exist
    terraform workspace select ${ENVIRONMENT} 2>/dev/null || terraform workspace new ${ENVIRONMENT}
    
    log_info "Terraform initialization completed"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    log_info "Deploying infrastructure for environment: ${ENVIRONMENT}"
    
    cd terraform
    
    # Initialize Terraform with proper backend handling
    init_terraform
    
    # Plan infrastructure changes
    log_info "Planning infrastructure changes..."
    terraform plan \
        -var="environment=${ENVIRONMENT}" \
        -var="project_name=${PROJECT_NAME}" \
        -var="aws_region=${AWS_REGION}" \
        -var="backend_image_tag=${IMAGE_TAG}" \
        -var="frontend_image_tag=${IMAGE_TAG}" \
        -out=tfplan
    
    # Apply infrastructure changes
    log_info "Applying infrastructure changes..."
    terraform apply tfplan
    
    # Store outputs for other commands
    terraform output -json > ../outputs.json
    
    log_info "Infrastructure deployment completed"
    terraform output
    
    cd - > /dev/null
}

# Build and push Docker images
build_and_push_images() {
    log_info "Building and pushing Docker images with tag: ${IMAGE_TAG}"
    
    # Login to ECR
    aws ecr get-login-password --region ${AWS_REGION} | \
        docker login --username AWS --password-stdin ${DOCKER_REGISTRY}
    
    # Get repository URLs from Terraform outputs
    if [ -f "outputs.json" ]; then
        BACKEND_REPO=$(jq -r '.backend_ecr_repository_url.value' outputs.json)
        FRONTEND_REPO=$(jq -r '.frontend_ecr_repository_url.value' outputs.json)
    else
        log_warn "outputs.json not found. Using default repository URLs."
        BACKEND_REPO="${DOCKER_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-backend"
        FRONTEND_REPO="${DOCKER_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-frontend"
    fi
    
    # Build backend image
    log_info "Building backend image..."
    docker build -t ${BACKEND_REPO}:${IMAGE_TAG} \
        -f backend/Dockerfile \
        --target production \
        backend/
    
    # Push backend image
    log_info "Pushing backend image..."
    docker push ${BACKEND_REPO}:${IMAGE_TAG}
    
    # Build frontend image (if directory exists)
    if [ -d "frontend" ]; then
        log_info "Building frontend image..."
        docker build -t ${FRONTEND_REPO}:${IMAGE_TAG} \
            -f frontend/Dockerfile \
            --target production \
            frontend/
        
        log_info "Pushing frontend image..."
        docker push ${FRONTEND_REPO}:${IMAGE_TAG}
    else
        log_warn "Frontend directory not found, skipping frontend image build"
    fi
    
    log_info "Images built and pushed successfully"
    
    # Store previous image tag for rollback
    store_previous_tag
}

# Deploy ECS services
deploy_services() {
    log_info "Deploying ECS services for environment: ${ENVIRONMENT}"
    
    cd terraform
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        init_terraform
    fi
    
    # Update services with new image tags
    terraform apply \
        -var="environment=${ENVIRONMENT}" \
        -var="project_name=${PROJECT_NAME}" \
        -var="aws_region=${AWS_REGION}" \
        -var="backend_image_tag=${IMAGE_TAG}" \
        -var="frontend_image_tag=${IMAGE_TAG}" \
        -auto-approve
    
    # Get service information
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
    BACKEND_SERVICE=$(terraform output -raw backend_service_name)
    
    cd - > /dev/null
    
    # Wait for deployment to complete
    log_info "Waiting for service deployment to complete..."
    aws ecs wait services-stable \
        --cluster ${CLUSTER_NAME} \
        --services ${BACKEND_SERVICE} \
        --region ${AWS_REGION}
    
    # Check if frontend service exists
    if terraform -chdir=terraform output frontend_service_name &>/dev/null; then
        FRONTEND_SERVICE=$(terraform -chdir=terraform output -raw frontend_service_name)
        aws ecs wait services-stable \
            --cluster ${CLUSTER_NAME} \
            --services ${FRONTEND_SERVICE} \
            --region ${AWS_REGION}
    fi
    
    log_info "Services deployed successfully"
}

# Run database migrations
run_migrations() {
    log_info "Running database migrations..."
    
    cd terraform
    
    # Get cluster information
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
    
    cd - > /dev/null
    
    # Get private subnet and security group for migration task
    PRIVATE_SUBNETS=$(terraform -chdir=terraform output -json private_subnet_ids | jq -r '.[]' | tr '\n' ',' | sed 's/,$//')
    SECURITY_GROUP=$(terraform -chdir=terraform output -raw security_group_ecs_id)
    
    # Run migrations using ECS task
    TASK_DEF_ARN=$(terraform -chdir=terraform output -raw migration_task_definition_arn 2>/dev/null || echo "")
    
    if [ -n "$TASK_DEF_ARN" ]; then
        log_info "Starting migration task..."
        TASK_ARN=$(aws ecs run-task \
            --cluster ${CLUSTER_NAME} \
            --task-definition ${TASK_DEF_ARN} \
            --launch-type FARGATE \
            --network-configuration "awsvpcConfiguration={subnets=[${PRIVATE_SUBNETS}],securityGroups=[${SECURITY_GROUP}],assignPublicIp=DISABLED}" \
            --query 'tasks[0].taskArn' \
            --output text \
            --region ${AWS_REGION})
        
        log_info "Migration task started: ${TASK_ARN}"
        
        # Wait for task to complete
        aws ecs wait tasks-stopped \
            --cluster ${CLUSTER_NAME} \
            --tasks ${TASK_ARN} \
            --region ${AWS_REGION}
        
        # Check task exit code
        EXIT_CODE=$(aws ecs describe-tasks \
            --cluster ${CLUSTER_NAME} \
            --tasks ${TASK_ARN} \
            --query 'tasks[0].containers[0].exitCode' \
            --output text \
            --region ${AWS_REGION})
        
        if [ "$EXIT_CODE" = "0" ]; then
            log_info "Database migrations completed successfully"
        else
            log_error "Database migrations failed with exit code: ${EXIT_CODE}"
            exit 1
        fi
    else
        log_warn "Migration task definition not found. Running migrations in backend container..."
        run_command_in_container "npm run db:migrate"
    fi
}

# Store current image tag for rollback capability
store_previous_tag() {
    if [ "$IMAGE_TAG" != "latest" ]; then
        CURRENT_TAG=$(aws ssm get-parameter \
            --name "/${PROJECT_NAME}/${ENVIRONMENT}/current-image-tag" \
            --query 'Parameter.Value' \
            --output text \
            --region ${AWS_REGION} 2>/dev/null || echo "")
        
        if [ -n "$CURRENT_TAG" ]; then
            aws ssm put-parameter \
                --name "/${PROJECT_NAME}/${ENVIRONMENT}/previous-image-tag" \
                --value "$CURRENT_TAG" \
                --type String \
                --overwrite \
                --region ${AWS_REGION} > /dev/null
        fi
        
        aws ssm put-parameter \
            --name "/${PROJECT_NAME}/${ENVIRONMENT}/current-image-tag" \
            --value "$IMAGE_TAG" \
            --type String \
            --overwrite \
            --region ${AWS_REGION} > /dev/null
    fi
}

# Rollback to previous deployment
rollback_deployment() {
    log_info "Rolling back deployment..."
    
    # Get previous image tag
    PREVIOUS_TAG=$(aws ssm get-parameter \
        --name "/${PROJECT_NAME}/${ENVIRONMENT}/previous-image-tag" \
        --query 'Parameter.Value' \
        --output text \
        --region ${AWS_REGION} 2>/dev/null || echo "")
    
    if [ -z "$PREVIOUS_TAG" ]; then
        log_error "No previous deployment found to rollback to"
        exit 1
    fi
    
    log_warn "Rolling back to image tag: ${PREVIOUS_TAG}"
    
    # Deploy previous version
    IMAGE_TAG=${PREVIOUS_TAG} deploy_services
    
    log_info "Rollback completed"
}

# Check deployment status
check_deployment_status() {
    log_info "Checking deployment status for environment: ${ENVIRONMENT}"
    
    if [ ! -f "outputs.json" ]; then
        log_warn "outputs.json not found. Running terraform output to get current state..."
        terraform -chdir=terraform output -json > outputs.json
    fi
    
    CLUSTER_NAME=$(jq -r '.ecs_cluster_name.value' outputs.json)
    BACKEND_SERVICE=$(jq -r '.backend_service_name.value' outputs.json)
    
    # Check ECS service status
    SERVICE_STATUS=$(aws ecs describe-services \
        --cluster ${CLUSTER_NAME} \
        --services ${BACKEND_SERVICE} \
        --query 'services[0].status' \
        --output text \
        --region ${AWS_REGION} 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$SERVICE_STATUS" = "ACTIVE" ]; then
        log_info "✅ Backend service is running"
        
        # Get running tasks count
        RUNNING_COUNT=$(aws ecs describe-services \
            --cluster ${CLUSTER_NAME} \
            --services ${BACKEND_SERVICE} \
            --query 'services[0].runningCount' \
            --output text \
            --region ${AWS_REGION})
        
        DESIRED_COUNT=$(aws ecs describe-services \
            --cluster ${CLUSTER_NAME} \
            --services ${BACKEND_SERVICE} \
            --query 'services[0].desiredCount' \
            --output text \
            --region ${AWS_REGION})
        
        log_info "Running tasks: ${RUNNING_COUNT}/${DESIRED_COUNT}"
        
        # Get application URL
        APP_URL=$(jq -r '.application_url.value' outputs.json)
        if [ -n "$APP_URL" ] && [ "$APP_URL" != "null" ]; then
            log_info "Application URL: ${APP_URL}"
            
            # Test health endpoint
            if curl -f "${APP_URL}/health" &>/dev/null; then
                log_info "✅ Health check passed"
            else
                log_warn "❌ Health check failed"
            fi
        fi
        
    else
        log_error "❌ Backend service is not running (Status: ${SERVICE_STATUS})"
    fi
}

# Show application logs
show_logs() {
    log_info "Showing application logs for environment: ${ENVIRONMENT}"
    
    if [ ! -f "outputs.json" ]; then
        terraform -chdir=terraform output -json > outputs.json
    fi
    
    LOG_GROUP=$(jq -r '.cloudwatch_log_group_backend.value' outputs.json)
    
    if [ -n "$LOG_GROUP" ] && [ "$LOG_GROUP" != "null" ]; then
        aws logs tail ${LOG_GROUP} --follow --region ${AWS_REGION}
    else
        log_error "Log group not found"
    fi
}

# Connect to running container
connect_to_container() {
    log_info "Connecting to running container..."
    
    if [ ! -f "outputs.json" ]; then
        terraform -chdir=terraform output -json > outputs.json
    fi
    
    CLUSTER_NAME=$(jq -r '.ecs_cluster_name.value' outputs.json)
    BACKEND_SERVICE=$(jq -r '.backend_service_name.value' outputs.json)
    
    # Get a running task ARN
    TASK_ARN=$(aws ecs list-tasks \
        --cluster ${CLUSTER_NAME} \
        --service-name ${BACKEND_SERVICE} \
        --query 'taskArns[0]' \
        --output text \
        --region ${AWS_REGION})
    
    if [ "$TASK_ARN" != "None" ] && [ -n "$TASK_ARN" ]; then
        log_info "Connecting to task: ${TASK_ARN}"
        
        aws ecs execute-command \
            --cluster ${CLUSTER_NAME} \
            --task ${TASK_ARN##*/} \
            --container backend \
            --command "/bin/sh" \
            --interactive \
            --region ${AWS_REGION}
    else
        log_error "No running backend tasks found"
    fi
}

# Run command in container
run_command_in_container() {
    local command="$1"
    log_info "Running command in container: ${command}"
    
    if [ ! -f "outputs.json" ]; then
        terraform -chdir=terraform output -json > outputs.json
    fi
    
    CLUSTER_NAME=$(jq -r '.ecs_cluster_name.value' outputs.json)
    BACKEND_SERVICE=$(jq -r '.backend_service_name.value' outputs.json)
    
    # Get a running task ARN
    TASK_ARN=$(aws ecs list-tasks \
        --cluster ${CLUSTER_NAME} \
        --service-name ${BACKEND_SERVICE} \
        --query 'taskArns[0]' \
        --output text \
        --region ${AWS_REGION})
    
    if [ "$TASK_ARN" != "None" ] && [ -n "$TASK_ARN" ]; then
        aws ecs execute-command \
            --cluster ${CLUSTER_NAME} \
            --task ${TASK_ARN##*/} \
            --container backend \
            --command "${command}" \
            --interactive \
            --region ${AWS_REGION}
    else
        log_error "No running backend tasks found"
    fi
}

# Destroy infrastructure
destroy_infrastructure() {
    log_warn "This will destroy ALL infrastructure for environment: ${ENVIRONMENT}"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [ "$confirm" = "yes" ]; then
        log_info "Destroying infrastructure..."
        
        cd terraform
        
        # Initialize Terraform if needed
        if [ ! -d ".terraform" ]; then
            init_terraform
        fi
        
        terraform destroy \
            -var="environment=${ENVIRONMENT}" \
            -var="project_name=${PROJECT_NAME}" \
            -var="aws_region=${AWS_REGION}" \
            -auto-approve
        
        log_info "Infrastructure destroyed"
        cd - > /dev/null
        
        # Clean up outputs file
        rm -f outputs.json
    else
        log_info "Destruction cancelled"
    fi
}

# Main script logic
main() {
    case "${1:-}" in
        "infra")
            check_prerequisites
            deploy_infrastructure
            ;;
        "images")
            check_prerequisites
            build_and_push_images
            ;;
        "services")
            check_prerequisites
            deploy_services
            ;;
        "migrate")
            check_prerequisites
            run_migrations
            ;;
        "rollback")
            check_prerequisites
            rollback_deployment
            ;;
        "destroy")
            check_prerequisites
            destroy_infrastructure
            ;;
        "status")
            check_prerequisites
            check_deployment_status
            ;;
        "logs")
            check_prerequisites
            show_logs
            ;;
        "shell")
            check_prerequisites
            connect_to_container
            ;;
        "help"|"")
            print_usage
            ;;
        *)
            log_error "Unknown command: $1"
            print_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

log_info "Operation completed successfully"