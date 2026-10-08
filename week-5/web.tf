resource "kubernetes_deployment_v1" "web" {
  metadata {
    name = "web"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "web"
      }
    }

    template {
      metadata {
        labels = {
          app = "web"
        }
      }

      spec {
        container {
          name  = "web"
          image = "week-4-web:latest"

          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5000
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

          env {
            name = "POSTGRES_DB"

            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.db_config.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name  = "POSTGRES_HOST"
            value = kubernetes_service_v1.db.metadata[0].name
          }

          env {
            name  = "FLASK_SECRET_KEY"
            value = var.flask_secret_key
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "web" {
  metadata {
    name = "web"
  }

  spec {
    selector = {
      app = "web"
    }

    type = "ClusterIP"

    port {
      port        = 5000
      target_port = 5000
    }
  }
}
