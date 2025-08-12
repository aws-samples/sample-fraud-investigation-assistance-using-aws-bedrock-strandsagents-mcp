<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# What is this module for?

This module creates following resources:

- Secrets Manager secret
- KMS encryption key
- Optional rotation configuration

# How do I use it?

Simple useage:

```hcl
module "secret" {
  source        = "../modules/secretsmanager_secret"
  secret_name        = "my-application-secrets"
  secret_description = "My application secrets"
  
  secret_values = {
    database_username = "admin"
    database_password = "<my_password>"
    api_key          = "<my_key>"
    environment      = "production"
  }

  tags = {
    Environment = "Production"
    Project     = "MyApp"
  }
}
```

# Inputs

| Variable name       | Required | Description                                                                        |
| ------------------- | -------- | ---------------------------------------------------------------------------------- |
| name_prefix         | Yes      | Prefix for the name of the secret                                                  |
| secret_string       | Yes      | Secret string to store inside the secret                                           |
| roles               | Yes      | Roles that will be granted permission to KMS key used for encryption of the secret |
| rotation_lambda_arn | No       | ARN of a lambda function that will be used to rotate the secret                    |
| rotation_interval   | No       | Rotation interval in days (defaults to 7)                                          |

# Outputs

| Output      | Description             |
| ----------- | ----------------------- |
| arn         | ARN of the secret       |
| secret_name | Generated secret's name |

# Ignored checkov warnings

None
