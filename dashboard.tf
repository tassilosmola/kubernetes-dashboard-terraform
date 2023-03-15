resource "kubernetes_namespace_v1" "kubernetes-dashboard" {
  metadata {
    name = var.kubernetes-dashboard-name
  }
}

resource "kubernetes_service_account_v1" "kubernetes-dashboard" {
  metadata {
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    name      = var.kubernetes-dashboard-name
    namespace = var.kubernetes-dashboard-name
  }

  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_service_v1" "kubernetes-dashboard" {
  metadata {
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    name      = var.kubernetes-dashboard-name
    namespace = var.kubernetes-dashboard-name
  }
  spec {
    selector = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    # session_affinity = "ClientIP"
    port {
      port        = 443
      target_port = 8443
    }
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_secret_v1" "kubernetes-dashboard-certs" {
  metadata {
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    name      = "kubernetes-dashboard-certs"
    namespace = var.kubernetes-dashboard-name
  }
  type = "Opaque"
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_secret_v1" "kubernetes-dashboard-csrf" {
  metadata {
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    name      = "kubernetes-dashboard-csrf"
    namespace = var.kubernetes-dashboard-name
  }
  type = "Opaque"
  data = {
    "csrf" = ""
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_secret_v1" "kubernetes-dashboard-key-holder" {
  metadata {
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    name      = "kubernetes-dashboard-key-holder"
    namespace = var.kubernetes-dashboard-name
  }
  type = "Opaque"
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_config_map_v1" "kubernetes-dashboard-settings" {
  metadata {
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    name      = "kubernetes-dashboard-settings"
    namespace = var.kubernetes-dashboard-name
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_role_v1" "kubernetes-dashboard" {
  metadata {
    name      = var.kubernetes-dashboard-name
    namespace = var.kubernetes-dashboard-name
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
  }
  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs", "kubernetes-dashboard-csrf"]
    verbs          = ["get", "update", "delete"]
  }
  # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["kubernetes-dashboard-settings"]
    verbs          = ["get", "update"]
  }
  # Allow Dashboard to get metrics.
  rule {
    api_groups     = [""]
    resources      = ["services"]
    resource_names = ["heapster", "dashboard-metrics-scraper"]
    verbs          = ["proxy"]
  }
  rule {
    api_groups     = [""]
    resources      = ["services/proxy"]
    resource_names = ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
    verbs          = ["get"]
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_cluster_role_v1" "kubernetes-dashboard" {
  metadata {
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    name = var.kubernetes-dashboard-name
  }
  # Allow Metrics Scraper to get metrics from the Metrics server
  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_role_binding_v1" "kubernetes-dashboard" {
  metadata {
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
    name      = var.kubernetes-dashboard-name
    namespace = var.kubernetes-dashboard-name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = var.kubernetes-dashboard-name
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.kubernetes-dashboard-name
    namespace = var.kubernetes-dashboard-name
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_cluster_role_binding_v1" "kubernetes-dashboard" {
  metadata {
    name = var.kubernetes-dashboard-name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.kubernetes-dashboard-name
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.kubernetes-dashboard-name
    namespace = var.kubernetes-dashboard-name
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_deployment" "kubernetes-dashboard" {
  metadata {
    name      = var.kubernetes-dashboard-name
    namespace = var.kubernetes-dashboard-name
    labels = {
      "${var.app-selector}" = var.kubernetes-dashboard-name
    }
  }

  spec {
    replicas               = 1
    revision_history_limit = 10

    selector {
      match_labels = {
        "${var.app-selector}" = var.kubernetes-dashboard-name
      }
    }

    template {
      metadata {
        labels = {
          "${var.app-selector}" = var.kubernetes-dashboard-name
        }
      }

      spec {
        container {
          image             = "kubernetesui/dashboard:v2.0.0"
          name              = var.kubernetes-dashboard-name
          image_pull_policy = "Always"
          port {
            container_port = 8443
            protocol       = "TCP"
          }
          args = [
            "--auto-generate-certificates",
            "--namespace=kubernetes-dashboard"
            # Uncomment the following line to manually specify Kubernetes API server Host
            # If not specified, Dashboard will attempt to auto discover the API server and connect
            # to it. Uncomment only if the default does not work.
            # - --apiserver-host=http://my-address:port
          ]
          volume_mount {
            name       = "kubernetes-dashboard-certs"
            mount_path = "/certs"
          }
          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              scheme = "HTTPS"
              path   = "/"
              port   = 8443
            }
            initial_delay_seconds = 30
            timeout_seconds       = 30
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_user                = 1001
            run_as_group               = 2001
          }
        }
        volume {
          name = "kubernetes-dashboard-certs"
          secret {
            secret_name = "kubernetes-dashboard-certs"
          }
        }
        volume {
          name = "tmp-volume"
          empty_dir {

          }
        }
        service_account_name = var.kubernetes-dashboard-name
        node_selector = {
          "kubernetes.io/os" : "linux"
        }
        # Comment the following tolerations if Dashboard must not be deployed on master
        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_service_v1" "dashboard-metrics-scraper" {
  metadata {
    labels = {
      "${var.app-selector}" = "dashboard-metrics-scraper"
    }
    name      = "dashboard-metrics-scraper"
    namespace = var.kubernetes-dashboard-name
  }
  spec {
    selector = {
      "${var.app-selector}" = "dashboard-metrics-scraper"
    }
    port {
      port        = 8080
      target_port = 8080
    }
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_deployment" "dashboard-metrics-scraper" {
  metadata {
    name      = "dashboard-metrics-scraper"
    namespace = var.kubernetes-dashboard-name
    labels = {
      "${var.app-selector}" = "dashboard-metrics-scraper"
    }
  }

  spec {
    replicas               = 1
    revision_history_limit = 10

    selector {
      match_labels = {
        "${var.app-selector}" = "dashboard-metrics-scraper"
      }
    }

    template {
      metadata {
        labels = {
          "${var.app-selector}" = "dashboard-metrics-scraper"
        }
        annotations = {
          "seccomp.security.alpha.kubernetes.io/pod" = "runtime/default"
        }
      }
      spec {
        container {
          image = "kubernetesui/metrics-scraper:v1.0.4"
          name  = "dashboard-metrics-scraper"
          port {
            container_port = 8000
            protocol       = "TCP"
          }
          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_user                = 1001
            run_as_group               = 2001
          }
        }

        volume {
          name = "tmp-volume"
          empty_dir {

          }
        }
        service_account_name = var.kubernetes-dashboard-name
        node_selector = {
          "kubernetes.io/os" : "linux"
        }
        # Comment the following tolerations if Dashboard must not be deployed on master
        toleration {
          key    = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }
      }
    }
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_service_account_v1" "admin-user" {
  metadata {
    name      = "admin-user"
    namespace = var.kubernetes-dashboard-name
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard
  ]
}

resource "kubernetes_secret_v1" "admin-user" {
  metadata {
    name      = "admin-user-token"
    namespace = var.kubernetes-dashboard-name
    annotations = {
      "kubernetes.io/service-account.name" = "admin-user"
    }
  }
  type = "kubernetes.io/service-account-token"
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard,
    kubernetes_service_account_v1.admin-user
  ]
}

resource "kubernetes_cluster_role_binding_v1" "admin-user" {
  metadata {
    name = "admin-user"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "admin-user"
    namespace = var.kubernetes-dashboard-name
  }
  depends_on = [
    kubernetes_namespace_v1.kubernetes-dashboard,
    kubernetes_service_account_v1.admin-user
  ]
}