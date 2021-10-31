terraform {
  backend "gcs" {
    bucket = "hands_on_kubernetes_multi_cluster_gateway_tfstate"
    prefix = "terraform/gcp"
  }
}