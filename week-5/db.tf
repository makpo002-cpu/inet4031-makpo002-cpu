resource "kubernetes_config_map_v1" "db_config" {
  metadata {
    name = "db-config"
  }

  data = {
    POSTGRES_DB = var.postgres_db
  }
}

resource "kubernetes_secret_v1" "db_secret" {
  metadata {
    name = "db-secret"
  }

  type = "Opaque"

  data = {
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
  }
}

resource "kubernetes_persistent_volume_claim_v1" "db_data" {
  metadata {
    name = "db-data"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "db" {
  metadata {
    name = "db"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "db"
      }
    }

    template {
      metadata {
        labels = {
          app = "db"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:16"
          args = [
            "-c",
            "shared_preload_libraries=pg_stat_statements"
          ]
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
          port {
            container_port = 5432
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.db_config.metadata[0].name
            }
          }

          env {
            name = "POSTGRES_USER"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db_secret.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db_secret.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "db-data"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "db-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.db_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "db" {
  metadata {
    name = "db"
  }

  spec {
    selector = {
      app = "db"
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "kubernetes_deployment_v1" "postgres_exporter" {
  metadata {
    name = "postgres-exporter"
    labels = {
      app = "postgres-exporter"
    }
  }

  spec {
    replicas = "1"

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

          volume_mount {
            name       = "db-credentials"
            mount_path = "/run/secrets"
            read_only  = true
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
      "prometheus.io/path"   = "/metrics"
      "prometheus.io/port"   = "9187"
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
    }

    type = "ClusterIP"
  }
}

