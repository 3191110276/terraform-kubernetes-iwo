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
  
  timeouts {
    delete = "3600s"
  }
  
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


resource "kubernetes_deployment" "iwok8scollector" {
  depends_on = [kubernetes_config_map.iwo-config]

  timeouts {
    create = "3600s"
  }

  metadata {
    name = "iwok8scollector"
    namespace = var.namespace
  }

  spec {
    replicas = 2

    progress_deadline_seconds = 3600

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "iwok8scollector"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "iwok8scollector"
        }
        annotations = {
          "kubeturbo.io/controllable" = "false"
        }
      }

      spec {
        service_account_name = "iwo-user"
        container {
          image = "intersight/kubeturbo:${var.collector_version}"
          name  = "iwo-k8s-collector"
          image_pull_policy = "IfNotPresent"
          args = ["--turboconfig=/etc/iwo/iwo.config", "--v=2", "--kubelet-https=true", "--kubelet-port=10250"] #, "--fail-volume-pod-moves=true"]
          volume_mount {
            name = "iwo-volume"
            mount_path = "/etc/iwo"
            read_only = "true"
          }
          volume_mount {
            name = "varlog"
            mount_path = "/var/log"
          }
        }
        container {
          image = "intersight/pasadena:${var.dc_version}"
          name  = "iwo-k8s-dc"
          image_pull_policy = "IfNotPresent"
          volume_mount {
            name = "varlog"
            mount_path = "/cisco/pasadena/logs"
          }
          env {
            name = "PROXY_PORT"
            value = "9004"
          }
        }
        volume {
          name = "iwo-volume"
          config_map {
            name = "iwo-config"
          }
        }
        volume {
          name = "varlog"
          empty_dir {}
        }
        restart_policy = "Always"
      }
    }
  }
}

resource "time_sleep" "wait" {
  depends_on = [kubernetes_deployment.iwok8scollector]

  create_duration = "10s"
}
