# What is this module for?
Provide information what is being created

# How do I use it?
Simple useage:

```hcl
module mymodule { 
   source = "../modules/mymodule" 
   arg1 = "my_bucket_" 
   arg2 = "something else" 
}
```
# Inputs
|Variable name|Required|Description|
|-------------|--------|-----------|
|required_var1|Yes|Explain use of the variable|
|optional_var1|No|Explain what happens when both specified and not specified|

# Outputs
|Output|Description|
|---|---|
|out1|What does this opuptut contain?|

# Ignored checkov warnings

|Warning|Description|Reason|
|---|---|---|
|CKV_AWS_XXX|Include checkov warning text| Explain why ignored|
