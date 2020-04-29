module "vpc" {
  source = "./vpc"

  name   = var.name
  region = var.region

  vms_cidr      = "10.10.0.0/16"
  pods_cidr     = "10.11.0.0/16"
  services_cidr = "10.12.0.0/16"
}

resource "google_container_cluster" "main" {
  provider = google-beta

  name     = var.name
  location = var.zone

  network    = module.vpc.name
  subnetwork = module.vpc.subnet_name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = module.vpc.pods_range_name
    services_secondary_range_name = module.vpc.services_range_name
  }

  release_channel {
    channel = var.release_channel
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  network_policy {
    provider = "CALICO"
    enabled = true
  }
}

resource "google_container_node_pool" "main" {
  provider = google-beta
  for_each = var.node_pools

  location = var.zone
  cluster  = google_container_cluster.main.name
  name     = each.key

  autoscaling {
    min_node_count = each.value.min
    max_node_count = each.value.max
  }

  management {
    auto_repair  = true
    auto_upgrade = each.value.auto_upgrade
  }

  node_config {
    preemptible     = each.value.preemptible
    machine_type    = each.value.machine_type
    local_ssd_count = each.value.local_ssds
    disk_size_gb    = each.value.disk_size
    disk_type       = each.value.disk_type
    image_type      = each.value.image

    workload_metadata_config {
      node_metadata = "SECURE"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "compute-rw",
      "storage-ro",
      "logging-write",
      "monitoring",
    ]
  }

  timeouts {
    create = "30m"
    delete = "30m"
  }
}