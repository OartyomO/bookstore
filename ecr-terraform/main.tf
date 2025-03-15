provider "aws" {
  region = "us-west-1"  # Change this to your desired region
}

# Define a list of repository names
locals {
  ecr_repositories = ["client", "server", "nginx"]
}

# Create ECR repositories using for_each
resource "aws_ecr_repository" "my_ecr_repositories" {
  for_each             = toset(local.ecr_repositories)
  name                 = each.key
  image_tag_mutability = "MUTABLE"  # Options: MUTABLE or IMMUTABLE
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-0d413c682033e11fd"
  instance_type = "t2.micro"
  key_name      = "my-key"

  tags = {
    Name = "MyUbuntuEC2Instance"
  }
}

# Create lifecycle policies for each ECR repository
resource "aws_ecr_lifecycle_policy" "my_ecr_lifecycle_policies" {
  for_each = aws_ecr_repository.my_ecr_repositories

  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ExpireOldImages"
        Effect    = "Allow"
        Principal = "*"
        Action    = "ecr:BatchDeleteImage"
        Resource  = "*"
        Condition = {
          "DateGreaterThan" = {
            "aws:CurrentTime" = "2023-01-01T00:00:00Z"  # Change this date as needed
          }
        }
      }
    ]
  })
}
