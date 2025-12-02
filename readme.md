
# 🚀 Production Ready EKS Cluster Using Terraform 

## 🌟 Project Overview

This repository provides a robust and production-ready foundation for hosting containerized applications on Amazon Web Services (AWS) using **Elastic Kubernetes Service (EKS)**. The entire infrastructure is defined, managed, and provisioned using **Terraform**.

This project focuses _only_ on the infrastructure layer, creating a secure environment ready for application deployment via standard Kubernetes tooling (`kubectl`).

### Key Design Principles

1.  **Security First:** Complete network isolation for worker nodes.
    
2.  **Controlled Access:** Only managed access via a hardened Jump Server (Bastion Host).
    
3.  **High Availability (HA):** Resources spanned across multiple availability zones.
    
4.  **Cost Efficiency:** Utilizing a mix of On-Demand and Spot instances for worker nodes.
    

## 📐 Architecture Components

**VPC**

Dedicated network with `/16` CIDR block.

Complete isolation from other environments.

**Public Subnets (2)**

Hosts the Jump Server and the NAT Gateway.

Controlled inbound access (SSH only).

**Private Subnets (2)**

Hosts EKS Worker Nodes and the EKS Control Plane ENIs.

No direct internet access (inbound).

**NAT Gateway**

Provides outbound internet connectivity to worker nodes (e.g., for pulling public images).

Ensures private subnets can reach the internet safely.

**Jump Server**

The single point of entry for SSH access to the worker nodes.

Highly secured bastion host, protected by a dedicated Security Group.

**EKS Cluster**

Deployed across private subnets.

Managed Control Plane, worker nodes use a mix of **On-Demand** (critical loads) and **Spot** (fault-tolerant/cost-saving loads).

## 🛠️ Getting Started

Follow these steps to deploy the EKS infrastructure in your AWS account.

### Prerequisites

Before you begin, ensure the following tools are installed and configured on your local machine:

1.  **AWS CLI:** Installed and configured with appropriate credentials (e.g., using `aws configure`).
    
2.  **Terraform:** Version 1.10 or higher.
    
3.  **S3 Backend Bucket:** A dedicated S3 bucket must be created in your AWS account to store the Terraform state file.
    

### Deployment Guide

#### 1. Clone the Repository

```
git clone https://github.com/Arijit9721/Production-Ready-EKS-Cluster-Using-Terraform.git
```

#### 2. Configure Backend and Variables

The project uses an S3 backend to securely store the Terraform state and enable collaboration/remote runs.

-   **Update `backend.tf`:** Open the `backend.tf` file and update the following configuration with the details of your s3 bucket used to store the state file.
        
-   **Review `variables.tf`:**  This file defines all input variables, including default VPC CIDRs, instance types, etc. 
**Note:** Confidential variables are not defined here and should be managed via a tfvars file.
    
-   **Create `terraform.tfvars`:** Create a new file named `terraform.tfvars` in the root directory. This file will hold the actual values for your deployment of the Confidential variables mentioned in the Variables. tf file.



#### 3. Initialization and Planning

1.  **Initialize Terraform:**  Initializes the backend and downloads the necessary providers.
    
   ```
 terraform init   
 ```
    
2.  **Validate Configuration:** Checks the syntax and configuration logic.
    
  ```
 terraform validate   
 ```
    
3.  **Review the Plan:** Generates an execution plan and inspect all resources that Terraform proposes to create, update, or destroy. 
    
 ```
 terraform plan -out=eks-prod.plan
```
    

4. **Apply the Changes:** If the plan looks correct, execute it to provision the EKS cluster and supporting infrastructure.
```
terraform apply eks-prod.plan
```

## 🧹 Cleanup

To destroy all provisioned resources and avoid recurring AWS charges:

⚠️ **WARNING:** This command will permanently destroy the EKS cluster, all associated worker nodes, VPC, and networking resources. Use with extreme caution.

```
terraform destroy
```
