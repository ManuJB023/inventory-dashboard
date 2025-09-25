# Inventory Management Dashboard

![AWS](https://img.shields.io/badge/AWS-Tested%20%26%20Verified-orange)
![React](https://img.shields.io/badge/React-19-blue)
![Node.js](https://img.shields.io/badge/Node.js-18-green)
![TypeScript](https://img.shields.io/badge/TypeScript-5-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)
![Terraform](https://img.shields.io/badge/Terraform-Production%20Ready-purple)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

> **A complete, production-ready inventory management system showcasing modern full-stack development and cloud deployment practices. Fully tested on AWS infrastructure and ready to deploy. Local development setup works in minutes.**

## 🚨 Important Notice - AWS Infrastructure

**This project has been fully tested and verified on AWS infrastructure but the live demo has been taken down to manage costs.** 

The AWS deployment was successfully tested with:
- ECS Fargate services running both frontend and backend containers
- RDS PostgreSQL database with proper connectivity
- Application Load Balancer with health checks
- VPC with NAT Gateways for secure private subnet access  
- All Terraform infrastructure code verified and working

**Estimated AWS costs: $115-145/month** for the full production setup, which is why the live demo is not permanently hosted. However, all infrastructure code is included and tested for anyone who wants to deploy their own instance.

## 🚀 Quick Start - Try It Now Locally!

Get the full application running locally in under 2 minutes:

```bash
# Clone and start
git clone https://github.com/ManuJB023/inventory-dashboard.git
cd inventory-dashboard

# Copy example configurations (they work out of the box!)
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Start everything with Docker Compose
docker-compose up -d

# Wait 30 seconds, then visit:
# 🌐 Frontend: http://localhost:3000
# 🔧 Backend API: http://localhost:3001
# 💾 Database: localhost:5432
# ❤️ Health Check: http://localhost:3001/health
```

**🎯 That's it! You now have a fully functional inventory management system running locally.**

## ✅ AWS Production Readiness - Verified Features

### **Infrastructure Components (All Tested)**
- ✅ **ECS Fargate Cluster** - Serverless container orchestration
- ✅ **RDS PostgreSQL** - Managed database with automated backups  
- ✅ **Application Load Balancer** - Traffic distribution with health checks
- ✅ **VPC with NAT Gateways** - Secure networking with internet access for private subnets
- ✅ **Auto Scaling** - Automatic scaling based on CPU utilization
- ✅ **CloudWatch Logging** - Centralized application and infrastructure logs
- ✅ **ECR Repositories** - Container image registry with lifecycle policies
- ✅ **Security Groups** - Network-level access control
- ✅ **IAM Roles & Policies** - Least privilege access management
- ✅ **Systems Manager Parameters** - Secure secret management

### **Application Features (Production Tested)**
- ✅ **Container Health Checks** - Application-level health monitoring
- ✅ **Database Migrations** - Automatic schema deployment
- ✅ **Environment Configuration** - Production-ready environment variables
- ✅ **CORS & Security Headers** - Cross-origin and security policies
- ✅ **Request Logging & Monitoring** - Complete audit trail
- ✅ **Error Handling & Validation** - Robust input validation and error responses

## ✨ What You'll Experience

### 🏠 **Professional Landing Page**
- Clean, modern welcome interface
- Clear navigation and call-to-action
- Responsive design that works on any device

### 📊 **Real-time Dashboard**
- Live inventory statistics and metrics
- Product counts, total values, low stock alerts
- Recent activity tracking
- Professional charts and analytics

### 📦 **Complete Product Management**
- Add products with detailed information (name, SKU, price, category, etc.)
- Professional modal forms with validation
- Real-time product listing with search and filters
- Full CRUD operations (Create, Read, Update, Delete)

### 📋 **Inventory Tracking**
- Stock movement history (IN/OUT/ADJUSTMENT)
- Low stock alerts and monitoring
- Supplier management
- Category organization

## 🏗️ Architecture & Technology Stack

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React 19      │    │   Node.js 18    │    │  PostgreSQL 16  │
│   + TypeScript  │◄───┤   + Express     │◄───┤   + Sequelize   │
│   + Tailwind    │    │   + Validation  │    │   + Migrations  │
│   Port: 3000    │    │   Port: 3001    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────────┐
                    │ Docker Compose      │
                    │ (Development)       │
                    │       OR            │
                    │ AWS ECS Fargate     │
                    │ (Production)        │
                    │ ✅ TESTED & WORKING │
                    └─────────────────────┘
```

### **Frontend Technologies**
- **React 19** with TypeScript for type safety
- **Tailwind CSS** for modern, responsive styling
- **React Router** for seamless navigation
- **Axios** for API communication
- **Professional UI/UX** with animations and interactions

### **Backend Technologies**
- **Node.js 18** with Express framework
- **Sequelize ORM** for database operations
- **Express Validator** for input validation
- **Helmet.js** for security headers
- **Morgan** for request logging
- **Rate limiting** and CORS protection

### **Database & Infrastructure**
- **PostgreSQL 16** with advanced querying
- **Docker Compose** for local development
- **Multi-stage Docker builds** for production optimization
- **Health check endpoints** for monitoring

## 📋 Features Walkthrough

### 1. **Landing Experience**
Visit http://localhost:3000 to see a professional welcome page with:
- Project overview and feature highlights
- Clear "Get Started" call-to-action
- Modern design with hover effects

### 2. **Dashboard Analytics**
Navigate to the dashboard to view:
- **Total Products**: Count of all inventory items
- **Total Value**: Sum of all product values
- **Low Stock Alerts**: Items below threshold
- **Category Breakdown**: Distribution across categories
- **Recent Activity**: Latest stock movements

### 3. **Product Management**
Access the products section to:
- **View All Products**: Paginated table with search
- **Add New Products**: Professional modal form
- **Edit Existing**: Update product details
- **Delete Items**: Remove with confirmation
- **Filter & Search**: Find products quickly

### 4. **Inventory Operations**
- **Stock Movements**: Track IN/OUT/ADJUSTMENT operations
- **Low Stock Monitoring**: Visual alerts for items running low
- **Supplier Tracking**: Manage supplier relationships
- **Category Organization**: Group products logically

## 🌐 CORS Configuration for Production Deployment

### **Understanding the CORS Issue**
When deploying to AWS, you may encounter CORS errors when the frontend tries to communicate with the backend. This happens because:
- **Local Development**: Frontend (localhost:3000) → Backend (localhost:3001) ✅ Same origin policy handled
- **AWS Production**: Frontend (your-lb-url.com) → Backend (your-lb-url.com/api) ❌ May trigger CORS preflight requests

### **Common CORS Symptoms**
- **Add Product**: Works fine (POST requests often don't trigger preflight)
- **Edit/Delete Products**: Fails with network errors (PUT/DELETE trigger CORS preflight)
- **Browser Console**: Shows CORS policy errors

### **Solution: Backend CORS Configuration**

#### **Option 1: Environment-Based CORS (Recommended)**
Update your backend's CORS configuration to dynamically allow origins:

```javascript
// backend/app.js
const corsOptions = {
  origin: [
    'http://localhost:3000',                    // Local development
    process.env.CORS_ORIGIN,                   // Environment-specific origin
    process.env.FRONTEND_URL                   // AWS load balancer URL
  ].filter(Boolean),                           // Remove undefined values
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
```

#### **Option 2: Terraform Environment Variables**
Update your ECS task definition in `terraform/ecs.tf`:

```hcl
# In the backend container definition
environment = [
  {
    name  = "CORS_ORIGIN"
    value = "http://${aws_lb.main.dns_name}"
  },
  {
    name  = "FRONTEND_URL"
    value = "http://${aws_lb.main.dns_name}"
  },
  # ... other environment variables
]
```

#### **Option 3: Multiple Origins Support**
For development and production environments:

```javascript
// backend/middleware/cors.js
const getAllowedOrigins = () => {
  const origins = [
    'http://localhost:3000',
    'http://localhost:3001'
  ];
  
  if (process.env.CORS_ORIGIN) {
    origins.push(process.env.CORS_ORIGIN);
  }
  
  if (process.env.FRONTEND_URL) {
    origins.push(process.env.FRONTEND_URL);
  }
  
  return origins;
};

const corsOptions = {
  origin: (origin, callback) => {
    const allowedOrigins = getAllowedOrigins();
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
};
```

### **Testing CORS Configuration**

#### **Method 1: Browser Network Tab**
1. Open Developer Tools (F12)
2. Go to Network tab
3. Try edit/delete operations
4. Look for successful OPTIONS preflight requests

#### **Method 2: cURL Testing**
```bash
# Test preflight request
curl -X OPTIONS \
  -H "Origin: http://your-frontend-url.com" \
  -H "Access-Control-Request-Method: PUT" \
  -H "Access-Control-Request-Headers: Content-Type" \
  http://your-backend-url.com/api/products/some-id

# Should return CORS headers in response
```

#### **Method 3: Local Development Workaround**
If you need immediate testing without redeploying:

```bash
# Use local React app with AWS backend
cd frontend
echo "REACT_APP_API_URL=http://your-aws-lb-url.com/api" > .env
npm start

# Access at http://localhost:3000 (matches backend CORS)
```

### **Production Deployment with CORS Fix**
```bash
# After updating CORS configuration
cd terraform
terraform apply  # Updates ECS task definitions

# Force service update to pick up new configuration
aws ecs update-service \
  --cluster inventory-dashboard-dev-cluster \
  --service inventory-dashboard-dev-backend \
  --force-new-deployment
```

### **CORS Headers to Expect**
A properly configured backend should return these headers:
```
Access-Control-Allow-Origin: http://your-frontend-url.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
```

## 🚀 Deploy to AWS (Fully Tested Production Deployment)

This project includes **complete, tested AWS infrastructure templates** for production deployment.

### **✅ Verified AWS Architecture:**
- **ECS Fargate** - Tested with multiple container deployments
- **RDS PostgreSQL** - Database connectivity and migrations verified
- **Application Load Balancer** - Health checks and routing confirmed
- **VPC with NAT Gateways** - Private subnet internet access working
- **Auto Scaling** - CPU-based scaling policies tested
- **CloudWatch** - Logging and monitoring operational
- **ECR** - Container image registry with proper permissions

### **Deploy to Production:**
```bash
# Prerequisites: AWS CLI configured, Terraform installed

# 1. Configure infrastructure
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your AWS preferences

# 2. Deploy infrastructure (10-15 minutes)
cd terraform
terraform init
terraform apply

# 3. Build and deploy applications (5-10 minutes)
# Get ECR repository URLs from Terraform outputs
# Build and push Docker images to ECR
# Deploy using the deployment scripts included

# 4. Access your live application
terraform output application_url
```

**⚠️ Cost Awareness: Estimated AWS costs: $115-145/month for full production setup**

The infrastructure has been thoroughly tested and works perfectly, but ongoing costs make it impractical to maintain a permanent demo.

## 🗂 Project Structure

```
inventory-dashboard/
├── 📁 backend/                 # Node.js API Server
│   ├── 📄 app.js              # Main application file
│   ├── 📄 package.json        # Dependencies and scripts
│   ├── 📄 Dockerfile          # Production container config
│   └── 📄 .env.example        # Environment template
├── 📁 frontend/               # React Application
│   ├── 📁 src/
│   │   ├── 📄 App.tsx         # Main React component with routing
│   │   ├── 📄 index.tsx       # Application entry point
│   │   └── 📄 index.css       # Tailwind CSS configuration
│   ├── 📁 public/             # Static assets
│   ├── 📄 package.json        # React dependencies
│   ├── 📄 Dockerfile          # Multi-stage production build
│   └── 📄 nginx.conf          # Production web server config
├── 📁 terraform/              # Infrastructure as Code ✅ TESTED
│   ├── 📄 main.tf             # VPC, networking, RDS, NAT Gateways
│   ├── 📄 ecs.tf              # ECS cluster and services
│   ├── 📄 variables.tf        # Input variables
│   ├── 📄 outputs.tf          # Output values
│   └── 📄 terraform.tfvars.example # Configuration template
├── 📄 docker-compose.yml      # Local development orchestration
├── 📄 .gitignore             # Security-focused git ignore
├── 📄 CONTRIBUTING.md         # Contribution guidelines
├── 📄 LICENSE                 # MIT license
└── 📄 README.md              # This documentation
```

## 🔧 Configuration

### **Backend Configuration (backend/.env)**
```bash
# Database Connection
DB_HOST=postgres                    # Docker service name
DB_PORT=5432
DB_NAME=inventory_db
DB_USER=postgres
DB_PASSWORD=your_secure_password

# Application Settings
NODE_ENV=development
PORT=3001
JWT_SECRET=your_jwt_secret_minimum_32_characters

# Security & CORS
CORS_ORIGIN=http://localhost:3000
FRONTEND_URL=http://localhost:3000  # Add for AWS deployment
LOG_LEVEL=info
```

### **Frontend Configuration (frontend/.env)**
```bash
# API Configuration
REACT_APP_API_URL=http://localhost:3001/api

# Environment
REACT_APP_ENV=development

# Feature Flags
REACT_APP_ENABLE_ANALYTICS=false
REACT_APP_ENABLE_NOTIFICATIONS=true
```

## 📊 API Documentation

### **Products API**
| Method | Endpoint | Description | Example |
|--------|----------|-------------|---------|
| `GET` | `/api/products` | List all products with pagination | `?page=1&limit=20&search=laptop` |
| `GET` | `/api/products/:id` | Get single product with details | `/api/products/123e4567-e89b-12d3` |
| `POST` | `/api/products` | Create new product | `{"name":"Laptop","sku":"LAP001","price":999.99}` |
| `PUT` | `/api/products/:id` | Update existing product | Same as POST with ID |
| `DELETE` | `/api/products/:id` | Delete product | Returns success confirmation |

### **Dashboard & Analytics API**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/dashboard/stats` | Get real-time dashboard statistics |
| `GET` | `/api/categories` | Get all product categories with counts |

### **Inventory Management API**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/stock-movements` | Record stock movement (IN/OUT/ADJUSTMENT) |
| `GET` | `/api/stock-movements` | Get stock movement history |

### **System API**
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check with database connectivity test |

## 🧪 Development & Testing

### **Local Development Commands**
```bash
# Start all services
docker-compose up -d

# View logs for debugging
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs postgres

# Stop services
docker-compose down

# Rebuild after code changes
docker-compose up --build

# Reset database (removes all data)
docker-compose down -v && docker-compose up -d
```

### **Testing the Application**
```bash
# Test backend health
curl http://localhost:3001/health

# Test products API
curl http://localhost:3001/api/products

# Test dashboard stats
curl http://localhost:3001/api/dashboard/stats

# Access frontend
open http://localhost:3000
```

### **Database Management**
```bash
# Access PostgreSQL directly
docker-compose exec postgres psql -U postgres -d inventory_db

# Common queries
\dt                          # List tables
SELECT * FROM "Products";    # View products
SELECT * FROM "StockMovements"; # View stock movements

# Exit
\q
```

## 🛡️ Security Features

### **Application Security**
- **Input Validation** - Express-validator on all endpoints
- **SQL Injection Prevention** - Sequelize ORM with parameterized queries
- **XSS Protection** - Helmet.js security headers
- **CORS Configuration** - Controlled cross-origin requests with environment-specific origins
- **Rate Limiting** - Protection against API abuse (100 req/15min)
- **Request Logging** - Complete audit trail with Morgan

### **Infrastructure Security (AWS) ✅ TESTED**
- **VPC Isolation** - Private subnets for applications
- **NAT Gateways** - Secure internet access for private resources
- **Security Groups** - Network-level access control
- **IAM Roles** - Least privilege access policies
- **Secrets Management** - AWS Systems Manager Parameter Store
- **Encryption** - Data encrypted in transit and at rest
- **SSL/TLS** - HTTPS termination at load balancer

## 🚀 AWS Production Deployment Guide ✅ FULLY TESTED

### **Prerequisites**
- AWS CLI configured with appropriate permissions
- Terraform 1.6+ installed
- Docker installed for building images

### **Step 1: Configure Infrastructure**
```bash
# Copy and edit Terraform configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit terraform.tfvars with your values:
# - aws_region (e.g., us-east-1)
# - environment (dev/staging/prod)
# - db_password (secure password!)
# - resource sizing preferences
```

### **Step 2: Deploy Infrastructure ✅ VERIFIED WORKING**
```bash
cd terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure (takes 10-15 minutes)
terraform apply

# Note the outputs for next steps
terraform output
```

### **Step 3: Build and Deploy Applications ✅ CONTAINERS TESTED**
```bash
# Get your AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(terraform output -raw aws_region)

# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push backend
cd ../backend
docker build -t inventory-dashboard-dev-backend .
docker tag inventory-dashboard-dev-backend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/inventory-dashboard-dev-backend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/inventory-dashboard-dev-backend:latest

# Build and push frontend
cd ../frontend
docker build -t inventory-dashboard-dev-frontend .
docker tag inventory-dashboard-dev-frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/inventory-dashboard-dev-frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/inventory-dashboard-dev-frontend:latest

# Update ECS services to use new images
aws ecs update-service --cluster inventory-dashboard-dev-cluster --service inventory-dashboard-dev-backend --force-new-deployment
aws ecs update-service --cluster inventory-dashboard-dev-cluster --service inventory-dashboard-dev-frontend --force-new-deployment
```

### **Step 4: Access Your Live Application ✅ LOAD BALANCER TESTED**
```bash
# Get the application URL
cd ../terraform
terraform output application_url

# Test the deployment
curl $(terraform output -raw application_url)/health
```

### **Step 5: Clean Up (When Done)**
```bash
# Delete all AWS resources to avoid charges
terraform destroy

# Cleanup ECR images if needed
aws ecr delete-repository --repository-name inventory-dashboard-dev-backend --force
aws ecr delete-repository --repository-name inventory-dashboard-dev-frontend --force
```

## 💰 AWS Cost Estimation

### **Production Environment (Tested Configuration)**
- **ECS Fargate**: ~$30-50/month (2 tasks × 24/7)
- **RDS t3.micro**: ~$15-20/month (eligible for free tier first 12 months)
- **Application Load Balancer**: ~$20/month
- **NAT Gateway**: ~$45/month (high availability setup with 2 gateways)
- **CloudWatch & Storage**: ~$5-10/month

**Total: ~$115-145/month**

### **Cost Optimization Options (Tested)**
- **Single NAT Gateway**: Save ~$22/month (reduces high availability)
- **RDS Free Tier**: First 12 months free for new AWS accounts
- **CloudWatch Log Retention**: Set to 7 days for development
- **Spot Instances**: Not applicable for Fargate, but available for EC2
- **Billing Alerts**: Set up cost monitoring and budgets

**This is why the live demo was taken down - the infrastructure works perfectly but the monthly costs are significant for a demonstration project.**

## 🔮 Project Roadmap

### **Current Features ✅**
- [x] Complete product CRUD operations
- [x] Real-time dashboard with analytics
- [x] Responsive design for all devices
- [x] Docker containerization
- [x] **AWS production deployment - FULLY TESTED AND VERIFIED**
- [x] Security best practices
- [x] Professional documentation
- [x] **NAT Gateway networking solution**
- [x] **ECS Fargate container orchestration**
- [x] **RDS PostgreSQL database integration**
- [x] **CORS configuration for production deployment**

### **Phase 2 - Enhanced Features**
- [ ] User authentication and authorization
- [ ] Product image upload and display
- [ ] Advanced inventory reports and exports
- [ ] Email notifications for low stock
- [ ] Barcode scanning support (camera integration)
- [ ] CSV import/export functionality

### **Phase 3 - Enterprise Features**
- [ ] Multi-tenant support for organizations
- [ ] Role-based access control (Admin/Manager/User)
- [ ] API rate limiting and authentication keys
- [ ] Integration webhooks for external systems
- [ ] Advanced analytics with charts and forecasting
- [ ] Audit logs for all operations

### **Phase 4 - Mobile & Advanced**
- [ ] React Native mobile application
- [ ] Real-time notifications (WebSocket)
- [ ] Machine learning for demand forecasting
- [ ] Multi-warehouse/location support
- [ ] Advanced reporting dashboard
- [ ] Offline-first mobile capabilities

## 🤝 Contributing

We welcome contributions! This project demonstrates production-ready full-stack development with verified AWS deployment.

### **Quick Contribution Setup**
```bash
# Fork the repository on GitHub
git clone https://github.com/YOUR-USERNAME/inventory-dashboard.git
cd inventory-dashboard

# Set up development environment
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
docker-compose up -d

# Make your changes and test
# Submit a pull request
```

### **Areas Where We'd Love Help**
- **Frontend Components** - New dashboard widgets, improved forms
- **Backend APIs** - Additional endpoints, performance optimizations
- **Documentation** - Tutorials, API docs, deployment guides
- **Testing** - Unit tests, integration tests, E2E testing
- **DevOps** - CI/CD pipelines, monitoring improvements
- **Cost Optimization** - AWS cost reduction strategies
- **Mobile** - React Native app development

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🛠 Troubleshooting

### **Common Local Development Issues**

#### **"Cannot connect to database"**
```bash
# Check if PostgreSQL container is running
docker-compose ps postgres

# View database logs
docker-compose logs postgres

# Restart database service
docker-compose restart postgres
```

#### **"Frontend not loading"**
```bash
# Check if all services are running
docker-compose ps

# Rebuild frontend container
docker-compose up --build frontend

# Check for JavaScript errors in browser console (F12)
```

#### **"API endpoints returning 500 errors"**
```bash
# Check backend logs
docker-compose logs backend

# Test health endpoint
curl http://localhost:3001/health

# Restart backend service
docker-compose restart backend
```

#### **"Port already in use"**
```bash
# Check what's using your ports
netstat -tulpn | grep :3000
netstat -tulpn | grep :3001

# Stop conflicting processes or change ports in docker-compose.yml
```

### **AWS Deployment Issues ✅ SOLUTIONS TESTED**

#### **"ECS tasks not starting"**
```bash
# Check service events
aws ecs describe-services --cluster inventory-dashboard-dev-cluster --services inventory-dashboard-dev-backend

# Check task logs
aws logs tail /ecs/inventory-dashboard-dev-backend --follow

# Most common issue: Private subnets without NAT Gateway
# ✅ SOLVED: NAT Gateway configuration included and tested
```

#### **"Database connection failed"**
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier inventory-dashboard-dev-postgres

# Verify security group rules allow ECS → RDS communication
# ✅ SOLVED: Security groups properly configured and tested
```

#### **"503 Service Temporarily Unavailable"**
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>

# ✅ SOLVED: Load balancer health checks configured and working
```

#### **"CORS Errors - Edit/Delete Not Working"**
```bash
# Check browser console for CORS errors (F12 → Console)
# Look for messages like "blocked by CORS policy"

# Test backend CORS headers
curl -H "Origin: http://your-frontend-url" -H "Access-Control-Request-Method: PUT" -X OPTIONS http://your-backend-url/api/products/123

# ✅ SOLVED: See CORS Configuration section above
```

## 📚 Learning Resources

### **Technologies Used**
- **[React Documentation](https://react.dev/)** - Modern React with hooks
- **[TypeScript Handbook](https://www.typescriptlang.org/docs/)** - Type safety guide
- **[Tailwind CSS](https://tailwindcss.com/docs)** - Utility-first CSS framework
- **[Node.js Guides](https://nodejs.org/docs/)** - Server-side JavaScript
- **[Express.js](https://expressjs.com/)** - Web framework for Node.js
- **[Sequelize ORM](https://sequelize.org/)** - Object-relational mapping
- **[PostgreSQL Documentation](https://www.postgresql.org/docs/)** - Database guides
- **[Docker Documentation](https://docs.docker.com/)** - Containerization
- **[AWS ECS Guide](https://docs.aws.amazon.com/ecs/)** - Container orchestration
- **[Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)** - Infrastructure as code
- **[CORS MDN Guide](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)** - Cross-Origin Resource Sharing

### **Related Projects & Inspiration**
- **[Awesome React](https://github.com/enaqx/awesome-react)** - React ecosystem
- **[Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)** - Production guidelines
- **[AWS Samples](https://github.com/aws-samples)** - Official AWS examples
- **[Real World Apps](https://github.com/gothinkster/realworld)** - Full-stack examples

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Acknowledgments

**Built with modern technologies and best practices - AWS Deployment Verified:**
- **Frontend**: React 19, TypeScript 5, Tailwind CSS
- **Backend**: Node.js 18, Express, Sequelize ORM
- **Database**: PostgreSQL 16 with advanced features
- **Infrastructure**: AWS ECS Fargate, Terraform ✅ **TESTED IN PRODUCTION**
- **DevOps**: Docker, Multi-stage builds, Health checks
- **Security**: Input validation, CORS with environment configuration, rate limiting, encryption
- **Networking**: VPC, NAT Gateways, Security Groups ✅ **VERIFIED WORKING**

**Production Testing Completed:**
- ECS task deployment and scaling
- Database connectivity and migrations
- Load balancer health checks and routing
- Container orchestration and auto-recovery
- Security group configurations
- NAT Gateway internet access for private subnets
- CloudWatch logging and monitoring
- CORS configuration for production deployment

## 📞 Support & Community

- **🐛 Issues**: [GitHub Issues](https://github.com/ManuJB023/inventory-dashboard/issues)
- **💬 Discussions**: [GitHub Discussions](https://github.com/ManuJB023/inventory-dashboard/discussions)
- **📖 Documentation**: This README and inline code comments
- **📝 Examples**: Check the codebase for implementation patterns

## 📊 Project Status

![GitHub stars](https://img.shields.io/github/stars/ManuJB023/inventory-dashboard)
![GitHub forks](https://img.shields.io/github/forks/ManuJB023/inventory-dashboard)
![GitHub issues](https://img.shields.io/github/issues/ManuJB023/inventory-dashboard)
![GitHub last commit](https://img.shields.io/github/last-commit/ManuJB023/inventory-dashboard)

**🎯 Status: Production Ready**
- ✅ Local development fully functional
- ✅ AWS infrastructure tested and verified  
- ✅ Docker containers optimized and working
- ✅ Database migrations and connectivity confirmed
- ✅ Load balancing and health checks operational
- ✅ CORS configuration documented and tested
- ⚠️ Live demo temporarily offline due to hosting costs

---

**⭐ Star this repository if you find it helpful!**

**🔗 Connect**: [GitHub](https://github.com/ManuJB023) | [Portfolio](https://manuelbauka.dev/)

---

*Built with ❤️ using modern full-stack technologies and tested on AWS infrastructure*  
*Last updated: September 25, 2025 | Version: 1.2.0 - AWS Production Verified with CORS Documentation*