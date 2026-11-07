resource "kubernetes_deployment_v1" "postgres_exporter" {
  metadata {
    name = "postgres-exporter"
    labels = {
      app = "postgres-exporter"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres-exporter"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres-exporter"
        }
      }

      spec {
        automount_service_account_token = false
        container {
          name  = "postgres-exporter"
          image = "quay.io/prometheuscommunity/postgres-exporter:v0.17.1"

          env {
            name  = "DATA_SOURCE_URI"
            value = "db:5432/incidents?sslmode=disable"
          }

          env {
            name  = "DATA_SOURCE_USER_FILE"
            value = "/run/secrets/POSTGRES_USER"
          }

          env {
            name  = "DATA_SOURCE_PASS_FILE"
            value = "/run/secrets/POSTGRES_PASSWORD"
          }

          port {
            name           = "metrics"
            container_port = 9187
            protocol       = "TCP"
          }

          volume_mount {
            name       = "db-credentials"
            mount_path = "/run/secrets"
            read_only  = true
          }

          security_context {
            run_as_non_root            = true
            run_as_user                = 65534
            run_as_group               = 65534
            allow_privilege_escalation = false
            read_only_root_filesystem  = true

            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }

        volume {
          name = "db-credentials"

          secret {
            secret_name = "db-secret"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "postgres_exporter" {
  metadata {
    name = "postgres-exporter"

    labels = {
      app = "postgres-exporter"
    }

    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "9187"
      "prometheus.io/path"   = "/metrics"
    }
  }

  spec {
    selector = {
      app = "postgres-exporter"
    }

    port {
      name        = "metrics"
      port        = 9187
      target_port = "metrics"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
