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
