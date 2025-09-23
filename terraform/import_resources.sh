#!/bin/bash
# Import existing resources into Terraform state

echo "Importing existing AWS resources into Terraform state..."

# Import IAM roles
echo "Importing IAM roles..."
terraform import aws_iam_role.ecs_task_execution inventory-dashboard-dev-ecs-task-execution-role
terraform import aws_iam_role.ecs_task inventory-dashboard-dev-ecs-task-role

# Import DB subnet group
echo "Importing DB subnet group..."
terraform import aws_db_subnet_group.main inventory-dashboard-dev-db-subnet-group

echo ""
echo "Import completed! Now running terraform plan to check the state..."
terraform plan

echo ""
echo "If the plan shows no changes or only minor changes, run:"
echo "terraform apply"