<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# What is this module for?
This module creates following resources:
* IAM role to enable API gateway to use CloudWatch logs
* API gateway account using the role

# How do I use it?
Simple useage:

```hcl
module logging { 
   source = "../modules/apigatewa_logging" 
}
```
# Inputs
None
# Outputs
None
# Ignored checkov warnings

|Warning|Description|Reason|
|---|---|---|

