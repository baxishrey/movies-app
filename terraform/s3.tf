resource "aws_s3_bucket" "backend" {
  bucket = "tf-backend"

}

resource "aws_s3_bucket_versioning" "backend_versioning" {
  bucket = aws_s3_bucket.backend.bucket

  versioning_configuration {
    status = "Enabled"
  }
}
