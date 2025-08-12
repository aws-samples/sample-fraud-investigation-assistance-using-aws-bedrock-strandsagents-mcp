<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# What is this module for?
This module creates following resources:
* RDS Aurora cluster
* RDS cluster instances
* RDS subnet group
* Backup plan
* IAM roles for backup and monitoring

# How do I use it?
Simple usage:

```hcl
module "rds_aurora" {
  source                = "../modules/rds_aurora"
  subnet_ids            = module.vpc.vpc_private_subnet_ids
  database_name         = "aurora_db"
  master_username       = "master"
  master_password       = random_password.master_password.result
  cluster_engine        = "aurora-postgresql"
  cluster_identifier    = "aurora"
  instance_class        = "db.t3.medium"
  backup_kms            = module.kms.arn 
}
```
# Inputs
|Variable name|Required|Description|
|-------------|--------|-----------|
|cluster_identifier|no|Identifier of the new cluster. A random id is generated if not specified|
|cluster_engine|no|Defaults to aurora if non specified. Allowed values are **aurora**, **aurora-mysql**, **aurora-postgresql**, **mysql** and **postgres**|
|database_name|no|Name of the database cluster|
|master_username|yes|Username of the master account|
|subnet_ids|yes|Subnets which to configure the cluster will be deployed|
|security_group_ids|no|Security groups to attach to the cluster|
|instance_class|yes|Instance type of the cluster instances. Make sure to check the instance type vs engine type compatibility [here](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.DBInstanceClass.html)|
|engine_mode|no|Defaults to **provisioned**|
|enable_http_endpoint|no|Only used if engine_mode is set to **serverless**|
|master_password|yes|Password of the master account|
|backup_kms|yes|KMS key ARN to encrypt the backup vault|
|port|no|Port on which to connect to the cluster|

# Outputs
|Output|Description|
|---|---|
|cluster_arn|ARN of the rds cluster|
|cluster_identifier|Cluster identifier of the rds cluster|
|cluster_resource|Cluster resource id of the rds cluster|
|cluster_instances|List of instances that are part of the rds cluster|
|instance_id|ID of the rds instances|

# Ignored checkov warnings

|Warning|Description|Reason|
|---|---|---|
|CKV_AWS_166|Ensure Backup Vault is encrypted at rest using KMS CMK| False negative, since KMS key defined in resources main.tf|
|CKV2_AWS_27|Ensure Postgres RDS as aws_rds_cluster has Query Logging enabled|Surplus to PoC requirements|