<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# What is this module for?
This module creates following resources:
* EC2 instance
* IAM role
* Instance profile

# How do I use it?
Simple useage:

```hcl
module "ec2" {
  source                 = "../modules/ec2"
  subnet_id              = module.vpc.vpc_private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]
  public_ip              = false
}
```
# Inputs
|Variable name|Required|Description|
|-------------|--------|-----------|
|instance_type|Yes|Type of the instance|
|subnet_id|Yes|Subnet in which the instance will be deployed|
|ami_id|No|AMI of the EC2 instance. Defaults to latest Linux AMI|
|name|No|Name of the EC2 instance|
|key_pair_key_name|No|Associate a key pair to the instance to allow SSH to the instance. Recommended parameter|
|vpc_security_group_ids|No|List of security group id(s) to which EC2 should be attached|
|public_ip|No|Allows the instance to get a public ip address. Defaults to false|
|source_dest_check|No|Enables source and destination IPs to be checked. Defaults to True. Usually set to false when EC2s are used as security/proxy/vpn appliances|
|user_data|No|User data of the instance. Defaults to empty|


# Outputs
|Output|Description|
|---|---|
|arn|ARN of the instance|
|private_dns|Private DNS of the instance|
|public_ip|Public IP of the instance|
|public_dns|Public DNS of the instance|
|iam_arn|ARN of the instance role|

# Ignored checkov warnings

None.

