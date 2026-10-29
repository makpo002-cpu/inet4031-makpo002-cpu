resource "kubernetes_network_policy_v1" "db_ingress" {
  metadata {
    name = "db-ingress-from-web"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "db"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "web"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = "5432"
      }
    }
  }
}
