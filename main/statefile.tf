terraform {
  backend "s3" {
    bucket         = "kiranitagi-tf-state-bucket"
    key            = "kiranaitaagi/terraform.tfstate"
    region         = "ap-south-1"
    profile        = "default"
    dynamodb_table = "terraform-lock"
  }
}
