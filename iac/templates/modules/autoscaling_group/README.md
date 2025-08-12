<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# What is this module for?

Autoscaling group with launch templateand and an ALB

# How do I use it?

See example folder. 

```hcl
module "autoscaling-group" {
  source              = "../../modules/autoscaling_group"
  vpc                 = module.vpc.vpc_id
  subnet_ids          = module.vpc.vpc_private_subnet_ids
  asg_security_groups = [aws_security_group.sg.id]
  user_data           = <<EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl start httpd.service
    sudo systemctl enable httpd.service
    echo “Hello World > /var/www/html/index.html
  EOF
  
}

```
# Inputs
|Variable name|Required|Description|
|-------------|--------|-----------|
|ami_id|No|AMI of the EC2 instance. Optional, pulls latest linux AMI by default.|
|instance_type|Yes|Type of the instance|
|vpc|Yes|VPC of the autoscaling group.|
|subnet_ids|Yes|List of subnet ids|
|asg_security_groups|No|List of security group id(s) to which autoscaling group should be attached|
|user_data|No|User data of the instances|

# Outputs
|Output|Description|
|---|---|
|alb_dns|DNS of the load balancer|
|iam_arn|ARN of ASG EC2 IAM role|

# Ignored checkov warnings

|Warning|Description|Reason|
|---|---|---|
|CKV_AWS_150|Ensure that Load Balancer has deletion protection enabled| Optional, depends on the use case|
|CKV_AWS_261|Ensure HTTP HTTPS Target group defines Healthcheck|Optional, depends on the use case|

