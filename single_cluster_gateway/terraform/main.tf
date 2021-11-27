provider "google" {
  project = "leaarninggcp-ash"
  region = "asia-northeast1"
}

# VPC作成
resource "google_compute_network" "gke_vpc" {
  name = "gke-vpc"
  auto_create_subnetworks = false
}

# 内部LBを作成する場合に必要な proxy only subnet を作成
# ref. https://cloud.google.com/load-balancing/docs/l7-internal/proxy-only-subnets
resource "google_compute_subnetwork" "proxy_only_subnet" {
name          = "proxy-only-subnetwork"
ip_cidr_range = "10.0.3.0/24" # cider for gke node
region        = "asia-northeast1"
network       = google_compute_network.gke_vpc.id
purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
role          = "ACTIVE"
}

# VPCネイティブクラスタを作成する際に指定する サブネットを作成
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnetwork"
  ip_cidr_range = "10.0.1.0/24" # cider for gke node
  region        = "asia-northeast1"
  network       = google_compute_network.gke_vpc.id
  secondary_ip_range {
    range_name    = "gke-pod"
    ip_cidr_range = "10.0.0.0/24"
  }
  secondary_ip_range {
    range_name    = "gke-service"
    ip_cidr_range = "10.0.2.0/24"
  }

  private_ip_google_access = true
}


# GKEのノードに割り当てるサービスアカウントを作成
resource "google_service_account" "gke_node_pool" {
  account_id = "gke-node-pool"
  display_name = "gke-node-pool"
  description = "A service account for GKE node"
}

# サービスアカウントに必要最低限の IAMロール（権限）を付与
resource "google_project_iam_member" "gke_node_pool" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/datastore.owner",
    "roles/storage.objectViewer"])

  role = each.value
  member = "serviceAccount:${google_service_account.gke_node_pool.email}"
}

# GKE クラスタを定義, VCP-Native, 公開クラスタ
resource "google_container_cluster" "main" {
  name = "gke-cluster"
  # 値に region, zone どちらも指定可能, zone を指定した場合には cluster will be a zonal cluster with a single cluster master.
  # region を指定した場合には the cluster will be a regional cluster with multiple masters spread across zones in the region, and with default node locations in those zones as well
  location = "asia-northeast1-a"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  # クラスタを作成するVPC, subnet を指定
  network = google_compute_network.gke_vpc.self_link
  subnetwork = google_compute_subnetwork.gke_subnet.self_link

  # vpc native cluster にするための設定
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name = "gke-pod"
    services_secondary_range_name = "gke-service"
  }
}

# GKE クラスタのノードを定義
resource "google_container_node_pool" "primary_nodes" {
  name = "node-pool"
  location = "asia-northeast1-a"
  cluster = google_container_cluster.main.name
  node_count = 1

  node_config {
    preemptible = true
    machine_type = "e2-medium"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # アクセススコープではすべてのサービスへの権限を付与し，サービスアカウント側で付与する権限を絞る
    service_account = google_service_account.gke_node_pool.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
