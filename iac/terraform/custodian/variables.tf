variable aws_profile {
  description = "AWS profile to use"
}

variable s3_bucket {
  description = "s3 bucket to use"
}

variable key {
  description = "key to use"
}
variable image_uri {
  description = "The URI of the Docker image in ECR"
  type        = string
}