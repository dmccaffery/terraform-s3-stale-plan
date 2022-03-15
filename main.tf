variable "diff" {
  type    = bool
  default = false
}

resource "null_resource" "resource" {
  triggers = {
    diff = var.diff
  }
}

resource "null_resource" "error" {
  for_each = toset(var.diff ? ["true"] : [])

  provisioner "local-exec" {
    when    = create
    command = "exit 1"
  }
}

resource "random_pet" "name" {
  length    = 2
  separator = "-"
  prefix    = "terraform"
}

resource "aws_s3_bucket" "state" {
  bucket        = random_pet.name.id
  force_destroy = true
}

resource "aws_s3_bucket_acl" "state" {
  bucket = aws_s3_bucket.state.id
  acl    = "private"
}

resource "aws_dynamodb_table" "lock" {
  name         = random_pet.name.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "local_file" "backend" {
  filename        = "${path.module}/backend.tf"
  file_permission = "0644"
  content         = <<-EOT
    terraform {
        backend "s3" {
            key            = "terraform.tfstate"
            region         = "${data.aws_region.current.name}"
            bucket         = "${aws_s3_bucket.state.id}"
            dynamodb_table = "${aws_dynamodb_table.lock.id}"
        }
    }
    EOT
}
