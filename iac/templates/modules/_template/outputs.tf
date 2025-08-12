#
# Create outputs here
#
output "some_output" {
  description = "Description of the output"
  value       = aws_s3_bucket.bucket.name
}