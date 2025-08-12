<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: MIT-0 -->

# What is this module for?
This module creates following resources:
* REST API 
* Two stages (prod and test) with deployments
* Optional custom domain  and DNS records in route 53

# How do I use it?
Simple useage:

```hcl
module api {
  source = "../modules/apigateway_rest"
  api_name = "Test API"
  api_spec = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "Partner platform API"
      version = "1.0"
    },
    paths = {
        "/api/hello" = {
        get = {
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${var.target_region}:lambda:path/2015-03-31/functions/${module.lambda.arn}:$${stageVariables.lambdaAlias}/invocations"
          }
        }
      } 
      "/api/mock" = {
        get = {
          responses = {
            "200" = {
              "description" = "200 response",
              "content"     = {}
            }
          }
          x-amazon-apigateway-integration = {
            responses = {
              "2\\d{2}" = {
                statusCode = "200",
                responseTemplates = {
                  "application/json" = "{ \"someCode\": 200}"
                }
              }
            },
            requestTemplates = {
              "application/json" = "{\n   \"statusCode\": 200\n}"
            },
            passthroughBehavior = "never"
            type                = "mock"
          }
        }
      }    
    }
    components = {
    }
  })
}
```
**NOTE:**
If a lambda function is to be used as a backend for the API, then it is necessary to grant permissions to invoke lambda throught the API gateway. Sample of how to do that is shown below:
```
resource "aws_lambda_permission" "api_access" {
  for_each      = toset(["prod", "test"])
  statement_id  = "API"
  action        = "lambda:InvokeFunction"
  function_name = "test"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*/*"
  qualifier     = each.key
}
```

# Inputs
|Variable name|Required|Description|
|-------------|--------|-----------|
|api_name|Yes|The name of the API to be created|
|api_spec|Yes|Open API specification for the API|
|user_pool_arn|No|ARN of a Cognito user pool to be used for authorization|
|api_domain_name|No|Custom domain name for the API. If specified, requires **r53_zone_id** and **certificate_arn** arguments|
|r53_zone_id|No|Id of the Route53 zone where the DNS records are to be created|
|certificate_arn|No|ARN of the TLS certificate to be used (required for custom domain name)|


# Outputs
|Output|Description|
|---|---|
|rest_api_id|ID of the API created|
|execution_arn|Execution ARN of the API, required to create lambda permissions (if necessary)|
|endpoint_url|URL of the prod stage of the API|
|endpoint_hostname|Host name of the prod stage endpoint URL|
|endpoint_path|Path of the prod statge endpoint URL|

# Ignored checkov warnings

|Warning|Description|Reason|
|---|---|---|
|CKV_AWS_225|Ensure API Gateway method setting caching is enabled|No caching to ensure strong consistency.|
|CKV_AWS_120|Ensure API Gateway caching is enabled|No caching to ensure strong consistency.|
|CKV2_AWS_51|Ensure AWS API Gateway endpoints uses client certificate authentication|Requires backend to implement cert based authentication which is surplus to requirements for most POCs|

