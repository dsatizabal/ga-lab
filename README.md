# AWS Global Accelerator Lab - SAP-02 Exam Preparation

This Terraform project demonstrates a multi-region serverless architecture using AWS Lambda, Application Load Balancers (ALB), and AWS Global Accelerator. It's designed as a hands-on lab for the **AWS Certified Solutions Architect - Professional (SAP-02)** certification exam.

## 🏗️ Architecture Overview

The infrastructure deploys a simple "Hello World" Lambda function exposed via Application Load Balancers across three AWS regions, with AWS Global Accelerator providing global routing and low-latency access.

### Architecture Components

```
┌─────────────────────────────────────────────────────────────┐
│              AWS Global Accelerator                         │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  DNS: *.awsglobalaccelerator.com                    │  │
│  │  Anycast IPs: 2 static IPv4 addresses               │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
   │ us-east-1│    │eu-west-1│    │ap-southeast-1│
   └────┬────┘    └────┬────┘    └────┬────┘
        │               │               │
   ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
   │   ALB   │    │   ALB   │    │   ALB   │
   └────┬────┘    └────┬────┘    └────┬────┘
        │               │               │
   ┌────▼────┐    ┌────▼────┐    ┌────▼────┐
   │ Lambda  │    │ Lambda  │    │ Lambda  │
   └─────────┘    └─────────┘    └─────────┘
```

### Regions Deployed

- **us-east-1** (N. Virginia, USA)
- **eu-west-1** (Ireland, Europe)
- **ap-southeast-1** (Singapore, Asia Pacific)

### Resources Per Region

Each region includes:
- **VPC** with public subnets (2 subnets across 2 availability zones)
- **Internet Gateway** for public internet access
- **Route Tables** for public subnet routing
- **Security Group** allowing HTTP traffic on port 80
- **Application Load Balancer** (Internet-facing)
- **Lambda Function** (Node.js 20.x) with IAM execution role
- **ALB Target Group** (Lambda type)
- **ALB Listener** (HTTP on port 80)
- **ALB Listener Rule** (path-based routing to `/ga`)
- **Lambda Permission** (allowing ALB to invoke Lambda)

### Global Accelerator

- **Global Accelerator** with TCP listener on port 80
- **Endpoint Groups** (one per region) pointing to regional ALBs
- **Health Checks** (HTTP on port 80, path `/`)
- **Static Anycast IPs** (2 IPv4 addresses)

## 📋 Prerequisites

- **Terraform** >= 1.6
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create:
  - VPC, Subnets, Internet Gateways, Route Tables
  - Application Load Balancers
  - Lambda Functions
  - IAM Roles and Policies
  - Global Accelerator
- **AWS Credentials** (Access Key ID and Secret Access Key)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ga-lab
```

### 2. Configure AWS Credentials

Copy the example terraform variables file and add your AWS credentials:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and add your AWS credentials:

```hcl
aws_access_key_id     = "YOUR_AWS_ACCESS_KEY_ID"
aws_secret_access_key = "YOUR_AWS_SECRET_ACCESS_KEY"
```

> ⚠️ **Security Note**: The `terraform.tfvars` file is excluded from version control via `.gitignore`. Never commit credentials to the repository.

### 3. Initialize Terraform

```bash
terraform init
```

This will:
- Download required providers (AWS >= 5.50, Archive >= 2.4)
- Initialize Terraform modules

### 4. Review the Execution Plan

```bash
terraform plan
```

This will show you all resources that will be created (approximately 57 resources across 3 regions).

### 5. Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment. The deployment typically takes 5-10 minutes.

### 6. View Outputs

After deployment, view the outputs:

```bash
terraform output
```

You'll see:
- `alb_dns_by_region`: ALB DNS names for each region
- `lambda_arn_by_region`: Lambda function ARNs for each region
- `global_accelerator_dns_name`: Global Accelerator DNS name
- `global_accelerator_ip_addresses`: Static Anycast IP addresses

## 🧪 Testing the Endpoints

### Test Regional ALBs Directly

Test each regional ALB endpoint directly:

```bash
# US East (N. Virginia)
curl http://<us-east-1-alb-dns-name>/ga

# EU West (Ireland)
curl http://<eu-west-1-alb-dns-name>/ga

# Asia Pacific (Singapore)
curl http://<ap-southeast-1-alb-dns-name>/ga
```

**Example Response:**
```json
{
  "message": "Hello from AWS Lambda via Global Accelerator demo",
  "region": "us-east-1",
  "time": "2024-01-15T10:30:00.000Z",
  "method": "GET",
  "path": "/ga",
  "clientIp": "203.0.113.1",
  "via": "ALB → Lambda",
  "headers": {
    "host": "ga-lab-alb-us-east-1-123456789.us-east-1.elb.amazonaws.com",
    "x-forwarded-for": "203.0.113.1",
    "x-forwarded-proto": "http",
    "x-forwarded-port": "80"
  }
}
```

### Test Global Accelerator DNS

Test using the Global Accelerator DNS name:

```bash
curl http://<global-accelerator-dns-name>/ga
```

The Global Accelerator will route your request to the nearest healthy endpoint based on your location.

### Test Global Accelerator Anycast IPs

Test using the static Anycast IP addresses directly:

```bash
# Get the IP addresses from terraform output
terraform output global_accelerator_ip_addresses

# Test with the first IP
curl -H "Host: <global-accelerator-dns-name>" http://<anycast-ip-1>/ga

# Test with the second IP
curl -H "Host: <global-accelerator-dns-name>" http://<anycast-ip-2>/ga
```

> **Note**: When using IP addresses directly, you may need to include the `Host` header with the Global Accelerator DNS name.

### Verify Region Routing

To verify that Global Accelerator routes to the nearest region, check the `region` field in the response. The response will show which regional Lambda function handled your request.

**Using curl with verbose output:**
```bash
curl -v http://<global-accelerator-dns-name>/ga
```

**Using PowerShell (Windows):**
```powershell
Invoke-WebRequest -Uri "http://<global-accelerator-dns-name>/ga" | Select-Object -ExpandProperty Content
```

## 🗑️ Destroying the Infrastructure

To remove all resources and avoid ongoing charges:

```bash
terraform destroy
```

Type `yes` when prompted. This will delete all resources created by Terraform.

> ⚠️ **Warning**: This will permanently delete all resources. Make sure you have backups if needed.

## 📁 Project Structure

```
ga-lab/
├── main.tf                          # Root module - providers and regional stacks
├── variables.tf                     # Root module variables
├── outputs.tf                      # Root module outputs
├── terraform.tfvars                # Local variables (gitignored)
├── terraform.tfvars.example        # Example variables file
├── regions.auto.tfvars.json        # Region configuration
├── .gitignore                      # Git ignore rules
│
└── modules/
    ├── alb_lambda/                 # ALB + Lambda module
    │   ├── main.tf                 # VPC, ALB, Lambda resources
    │   ├── variables.tf             # Module variables
    │   └── outputs.tf              # ALB DNS and Lambda ARN
    │
    ├── ga/                         # Global Accelerator module
    │   ├── main.tf                 # GA accelerator, listener, endpoints
    │   ├── variables.tf            # Module variables
    │   └── outputs.tf              # GA DNS and IP addresses
    │
    └── lambda_fn/                  # Lambda function module
        ├── main.tf                 # Lambda function and IAM role
        ├── index.mjs               # Lambda function code
        ├── lambda.zip              # Compiled Lambda package
        └── variables.tf            # Module variables
```

## 🔧 Configuration

### Customizing Regions

Edit `regions.auto.tfvars.json` to add or remove regions:

```json
{
  "regions": {
    "us-east-1": {
      "alb_path": "/ga",
      "lambda_memory_mb": 256,
      "lambda_timeout_s": 5,
      "alb_listener_port": 80
    },
    "eu-west-1": {
      "alb_path": "/ga"
    },
    "ap-southeast-1": {
      "alb_path": "/ga"
    }
  }
}
```

### Customizing Stack Name

Edit `terraform.tfvars`:

```hcl
stack_name_prefix = "my-custom-prefix"
```

This will prefix all resource names (e.g., `my-custom-prefix-alb-us-east-1`).

## 🔍 Key Technical Details

### Lambda Function

- **Runtime**: Node.js 20.x
- **Handler**: `index.handler`
- **Default Memory**: 128 MB (configurable per region)
- **Default Timeout**: 3 seconds (configurable per region)
- **IAM Role**: Uses `AWSLambdaBasicExecutionRole` for CloudWatch Logs

The Lambda function returns JSON with:
- Current AWS region
- Request metadata (method, path, client IP)
- Headers (including X-Forwarded-For)
- Timestamp

### Application Load Balancer

- **Type**: Application Load Balancer (Layer 7)
- **Scheme**: Internet-facing
- **Listener**: HTTP on port 80
- **Target Type**: Lambda
- **Path-based Routing**: Routes `/ga` path to Lambda

### Global Accelerator

- **Protocol**: TCP on port 80
- **Client Affinity**: NONE (stateless)
- **Health Checks**: HTTP on port 80, path `/`
- **Health Check Interval**: 30 seconds
- **Threshold Count**: 3 consecutive failures
- **Traffic Dial**: 100% (all traffic to healthy endpoints)

### VPC Configuration

- **CIDR Block**: 10.0.0.0/16 per region
- **Public Subnets**: 2 subnets (10.0.1.0/24, 10.0.2.0/24)
- **Availability Zones**: 2 AZs per region
- **Internet Gateway**: Attached for public internet access
- **Route Tables**: Public subnets route 0.0.0.0/0 via IGW

> **Note**: If a default VPC exists in a region, the module will create a new VPC. This ensures consistent networking across all regions.

## 💡 Recommendations and Improvements

### Security Enhancements

1. **Use HTTPS/TLS**: 
   - Add ACM certificates to ALB listeners
   - Configure HTTPS listeners (port 443)
   - Update Global Accelerator to use HTTPS

2. **WAF Integration**:
   - Add AWS WAF to ALBs for DDoS protection
   - Implement rate limiting and geo-blocking rules

3. **IAM Best Practices**:
   - Use IAM roles instead of access keys where possible
   - Implement least-privilege IAM policies
   - Consider using AWS SSO or temporary credentials

4. **Network Security**:
   - Implement security groups with least-privilege rules
   - Consider using VPC endpoints for AWS services
   - Add Network ACLs for additional layer of security

### Operational Improvements

1. **Monitoring and Logging**:
   - Enable CloudWatch Logs for Lambda functions
   - Set up CloudWatch Alarms for ALB and Lambda metrics
   - Configure Global Accelerator CloudWatch metrics

2. **Cost Optimization**:
   - Use Lambda Provisioned Concurrency only if needed
   - Consider ALB idle timeout tuning
   - Monitor Global Accelerator data transfer costs

3. **High Availability**:
   - Current setup is already multi-region
   - Consider adding more regions for better global coverage
   - Implement cross-region failover strategies

4. **Infrastructure as Code**:
   - Add Terraform state backend (S3 + DynamoDB)
   - Implement Terraform workspaces for environments
   - Add CI/CD pipeline for automated deployments

### Code Quality

1. **Terraform Best Practices**:
   - Add `terraform.tfstate` to `.gitignore` (already done)
   - Use remote state backend
   - Add input validation in variables
   - Consider using `terraform-docs` for documentation

2. **Lambda Function**:
   - Add error handling and retry logic
   - Implement structured logging
   - Add unit tests for Lambda function
   - Consider using Lambda Layers for shared code

3. **Module Structure**:
   - Add module versioning
   - Document module inputs/outputs
   - Add examples for module usage

### Additional Features

1. **Route 53 Integration**:
   - Add Route 53 hosted zone
   - Create alias records pointing to Global Accelerator
   - Implement health checks and failover

2. **API Gateway Alternative**:
   - Consider API Gateway for RESTful API patterns
   - Implement API versioning
   - Add API throttling and caching

3. **Content Delivery**:
   - Add CloudFront in front of Global Accelerator
   - Implement caching strategies
   - Add custom error pages

## 📚 AWS Services Used

This lab demonstrates the following AWS services and concepts:

- **Compute**: AWS Lambda (Serverless)
- **Networking**: 
  - VPC, Subnets, Internet Gateway, Route Tables
  - Application Load Balancer
  - AWS Global Accelerator
- **Security**: 
  - Security Groups
  - IAM Roles and Policies
- **Infrastructure as Code**: Terraform

## 🎓 SAP-02 Exam Relevance

This lab covers several key topics for the AWS Certified Solutions Architect - Professional exam:

1. **Multi-Region Architecture**: Deploying resources across multiple AWS regions
2. **Global Accelerator**: Understanding Anycast IPs, endpoint groups, and health checks
3. **Serverless Architecture**: Lambda functions with ALB integration
4. **Networking**: VPC design, public subnets, internet gateways
5. **High Availability**: Multi-region deployment for fault tolerance
6. **Infrastructure as Code**: Terraform for reproducible deployments

## 📝 License

This project is for educational purposes as part of AWS Solutions Architect Professional certification preparation.

## 🤝 Contributing

This is a lab project for certification preparation. Feel free to fork and modify for your own learning purposes.

## 📞 Support

For issues or questions:
1. Review the Terraform documentation: https://www.terraform.io/docs
2. Check AWS documentation for specific services
3. Review AWS Global Accelerator best practices

---

**Note**: This lab is designed for the **SAP-02** (AWS Certified Solutions Architect - Professional) exam preparation. Ensure you understand the concepts and can explain the architecture decisions during the exam.
