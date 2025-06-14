# Spring PetClinic Deployment on AWS using Terraform (3-Tier Architecture)

## Overview

This document outlines the step-by-step process followed to deploy the Spring PetClinic application on AWS using Terraform. The deployment includes a 3-tier architecture consisting of networking, compute, and database layers.

---

## 1. **Terraform Project Structure**

```
terraform_petclinic_project/
├── main.tf
├── variables.tf
├── outputs.tf
├── userdata.sh
├── modules/
│   ├── vpc
│   ├── alb
│   ├── asg
│   ├── rds
│   └── s3_backend
```

---

## 2. **Backend Configuration (Remote State)**

`statefile.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "kiranitagi-tf-state-bucket"
    key            = "kiranaitaagi/terraform.tfstate"
    region         = "ap-south-1"
    profile        = "default"
    dynamodb_table = "terraform-lock"
  }
}
```

### ✔️ Created S3 bucket and DynamoDB table manually before `terraform init`

---

## 3. **Networking Layer (VPC Module)**

* Created VPC with:

  * 2 Public Subnets (AZ1, AZ2)
  * 2 Private Subnets (AZ1, AZ2)
  * 2 Secure Subnets for RDS
  * NAT Gateway and Internet Gateway

---

## 4. **Security Groups**

* ALB Security Group (HTTP 80 inbound)
* EC2 Security Group (inbound from ALB SG)
* RDS Security Group (inbound from EC2 SG)

---

## 5. **Application Load Balancer (ALB Module)**

* Application Load Balancer in public subnets
* Target Group with port 80
* Listener forwarding to target group

---

## 6. **Launch Template & Auto Scaling Group (ASG Module)**

### ✅ AMI

Used the latest **Amazon Linux 2 AMI** via data source:

```hcl
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
```

### ✅ Launch Template

* Instance type: `t3.micro`
* Injected `userdata.sh`
* IAM instance profile: `EC2_SSM_Instance_Profile`

### ✅ User Data Script (docker-based deployment)

```bash
#!/bin/bash
cd
sudo yum update -y
sudo yum install docker containerd git screen -y
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose
systemctl enable docker.service --now
usermod -a -G docker ec2-user
systemctl restart docker.service
docker pull karthik0741/images:petclinic_img
docker run -d -e MYSQL_URL=jdbc:mysql://${mysql_url}/petclinic -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 80:8080 docker.io/karthik0741/images:petclinic_img
```

---

## 7. **RDS Module**

* Engine: `mysql`
* Version: `8.0.36`
* Instance Class: `db.t3.micro`
* Subnet Group in secure subnets
* Publicly accessible: true

---

## 8. **Troubleshooting Highlights**

| Issue                         | Resolution                                                  |
| ----------------------------- | ----------------------------------------------------------- |
| `502 Bad Gateway`             | Ensured EC2 was healthy and docker app listening on port 80 |
| ALB Target Unhealthy          | Verified security group, user data, app port                |
| Docker not found              | Fixed yum install and verified via SSM                      |
| RDS version error             | Corrected to supported `8.0.36`                             |
| IAM instance profile conflict | Removed existing profile manually                           |
| Terraform lock errors         | Created missing DynamoDB lock table                         |

---

## 9. **Final Output**

* Accessed application via ALB DNS:

  ```
  ```

[http://awsinfra-alb-229328048.ap-south-1.elb.amazonaws.com](http://awsinfra-alb-229328048.ap-south-1.elb.amazonaws.com)
\`\`

* Verified PetClinic home page loading successfully

---

## 10. **Lessons Learned**

* Always validate `userdata.sh` manually on an EC2 before using in ASG
* Use proper AMI type (Amazon Linux 2 recommended for docker)
* Use SSM Session Manager for debugging without public IP
* Terraform locking is critical — setup DynamoDB properly
* ALB 502 errors are usually app-level (check docker & port mapping)

---

## Status: ✅ Completed

---
