<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# What is this module for?
This module creates WAF ACL that is compliant with protosec requirements and best practices. Optionally it takes a list of IP CIDRs which can be used to limit access to particular range of IPs (e.g. Amazon corporate firewalls) effectively making the protected resource private.
Other than WAF acl, the module also creates KMS encrypted log groups for the WEB ACL logs.
When creating ACLs for CloudFront, the module's aws provider needs to be set to one in es-east-1 region. ACLs for the API gateway (adn other regional resources) must be created in appropriate regions and can use ambient aws provider.

# How do I use it?
Simple useage for CloudFront:

```hcl
module "waf-cloudfront" {
  providers = {
   aws = aws.us_east
  }
  source = "../../modules/waf"
  name   = "Cloudfront"
}
```

Here's an example of a regional ACL for the API gateway:

```
#
# ACL for API gateway with IP list
#
module "waf-api-ipset" {
  source            = "../../modules/waf"
  name              = "API-IP"
  scope             = "REGIONAL"
  description       = "ACL with IP white list"
  waf_whitelist_ips = ["13.248.16.0/25"]
}
```
# Inputs
|Variable name|Required|Description|
|-------------|--------|-----------|
|name|Yes|Name of the ACL|
|description|No|Description of the ACL|
|waf_whitelist_ip|No|List of CIDR blocks to be allowed access|
|scope|No|Scope of the ACL. Must be either "CLOUDFRONT" or "REGIONAL"|

# Outputs
|Output|Description|
|---|---|
|arn|ARN of the ACL created|

# Ignored checkov warnings

|Warning|Description|Reason|
|---|---|---|
|CKV_AWS_192|Ensure WAF prevents message lookup in Log4j2. See CVE-2021-44228 aka log4jshell|False posititve. AWS managed rule set included in the ACL|
