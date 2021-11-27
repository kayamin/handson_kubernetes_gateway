provider "google" {
  project = "leaarninggcp-ash"
  region = "asia-northeast1"
}

locals {
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
  name = "proxy-only-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  # cider for gke node
  region = local.region
  network = google_compute_network.gke_vpc.id
  purpose = "INTERNAL_HTTPS_LOAD_BALANCER"
  role = "ACTIVE"
}

# VPCネイティブクラスタを作成する際に指定する サブネットを作成
resource "google_compute_subnetwork" "gke_subnet" {
  for_each = {
    alpha = {
      node_cidr = "10.0.1.0/24", pod_cidr = "10.0.2.0/24", service_cidr = "10.0.3.0/24"
    }
    beta = {
      node_cidr = "10.0.4.0/24", pod_cidr = "10.0.5.0/24", service_cidr = "10.0.6.0/24"
    }
    gamma = {
      node_cidr = "10.0.7.0/24", pod_cidr = "10.0.8.0/24", service_cidr = "10.0.9.0/24"
    }
  }
  name = each.key
  ip_cidr_range = each.value["node_cidr"] # cider for gke node
  region = local.region
  network = google_compute_network.gke_vpc.id
  secondary_ip_range {
    range_name = "gke-pod"
    ip_cidr_range = each.value["pod_cidr"]
  }
  secondary_ip_range {
    range_name = "gke-service"
    ip_cidr_range = each.value["service_cidr"]
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
# １リソースで１つのロールしか紐付けられないので for_each でまとめて記述するように工夫
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
  for_each = {
    alpha = {
      location = "asia-northeast1-a", subnetwork = google_compute_subnetwork.gke_subnet["alpha"].self_link
    }
    beta = {
      location = "asia-northeast1-b", subnetwork = google_compute_subnetwork.gke_subnet["beta"].self_link
    }
    gamma = {
      location = "asia-northeast1-c", subnetwork = google_compute_subnetwork.gke_subnet["gamma"].self_link
    }
  }

  name = each.key
  # 値に region, zone どちらも指定可能, zone を指定した場合には cluster will be a zonal cluster with a single cluster master.
  # region を指定した場合には the cluster will be a regional cluster with multiple masters spread across zones in the region, and with default node locations in those zones as well
  location = each.value["location"]

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  # クラスタを作成するVPC, subnet を指定
  network = google_compute_network.gke_vpc.self_link
  subnetwork = each.value["subnetwork"]

  # vpc native cluster にするための設定
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name = "gke-pod"
    services_secondary_range_name = "gke-service"
  }

  # workload identity を有効にするための設定
  workload_identity_config {
    workload_pool = "${local.project}.svc.id.goog"
  }
}

# GKE クラスタのノードを定義
resource "google_container_node_pool" "primary_nodes" {
  for_each = {
    alpha = {
      location = "asia-northeast1-a"
    }
    beta = {
      location = "asia-northeast1-b"
    }
    gamma = {
      location = "asia-northeast1-c"
    }
  }

  name = each.key
  cluster = each.key
  location = each.value["location"]
  node_count = 1

  node_config {
    preemptible = true
    machine_type = "e2-standard-2"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # アクセススコープではすべてのサービスへの権限を付与し，サービスアカウント側で付与する権限を絞る
    service_account = google_service_account.gke_node_pool.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [google_container_cluster.main]
}

# GKEクラスタを GKE Hub のフリートに登録する
# https://cloud.google.com/kubernetes-engine/docs/how-to/enabling-multi-cluster-gateways#register_with
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_membership
resource "google_gke_hub_membership" "membership" {
  for_each = {
    alpha = {
      location = "asia-northeast1-a", cluster_primary_id = google_container_cluster.main["alpha"].id
    }
    beta = {
      location = "asia-northeast1-b", cluster_primary_id = google_container_cluster.main["beta"].id
    }
    gamma = {
      location = "asia-northeast1-c", cluster_primary_id = google_container_cluster.main["gamma"].id
    }
  }

  membership_id = each.key
  endpoint {
    gke_cluster {
      resource_link = each.value["cluster_primary_id"]
    }
  }
  authority {
    issuer = "https://container.googleapis.com/v1/${each.value["cluster_primary_id"]}"
  }

  depends_on = [google_container_cluster.main]
}

# GKE Hub のフリートでマルチクラスタサービス(MCS)を有効にする
# https://cloud.google.com/kubernetes-engine/docs/how-to/enabling-multi-cluster-gateways#enable_multi-cluster_services
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature
resource "google_gke_hub_feature" "multicluster-service-discovery" {
  provider = google-beta
  name = "multiclusterservicediscovery"
  project = local.project
  location = "global"

  depends_on = [google_container_node_pool.primary_nodes]
}

# MCS に必要な Identity and Access Management（IAM）権限を付与する
resource "google_project_iam_member" "gke_mcs" {
  role = "roles/compute.networkViewer"
  member = "serviceAccount:${local.project}.svc.id.goog[gke-mcs/gke-mcs-importer]"
}
