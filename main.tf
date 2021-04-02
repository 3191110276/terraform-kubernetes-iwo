############################################################
# REQUIRED PROVIDERS
############################################################
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
  }
}


############################################################
# INSTALL IWO
############################################################
resource "kubernetes_namespace" "iwo" {
  count = var.create_namespace ? 1 : 0
  
  metadata {
    name = "iwo"
  }
}

resource "kubernetes_service_account" "iwo-user" {
  depends_on = [kubernetes_namespace.iwo]
  
  metadata {
    name = "iwo-user"
    namespace = var.namespace
  }
}


resource "kubernetes_cluster_role_binding" "iwo-all-binding" {
  depends_on = [kubernetes_service_account.iwo-user]
  metadata {
    name = "iwo-all-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "iwo-user"
    namespace = var.namespace
  }
}


resource "kubernetes_config_map" "iwo-config" {
  depends_on = [kubernetes_namespace.iwo]
  
  metadata {
    name = "iwo-config"
    namespace = var.namespace
  }

  data = {
    "iwo.config" = <<EOT
    {
      "communicationConfig": {
        "serverMeta": {
          "proxy": "http://localhost:9004",
          "version": "${var.iwo_server_version}",
          "turboServer": "http://topology-processor:8080"
        }
      },
      "HANodeConfig": {
        "nodeRoles": ["master"]
      },
      "targetConfig": {
        "targetName": "${var.cluster_name}"
      },
      "daemonPodDetectors": {
        "namespaces": [],
        "podNamePatterns": []
      }
    }
    EOT
  }
}





