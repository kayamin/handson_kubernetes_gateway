terraform {
  backend "gcs" {
    bucket = "hands_on_kubernetese_gateway_tfstate"
    prefix = "terraform/gcp"
  }
}