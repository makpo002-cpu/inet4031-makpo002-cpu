output "web_port_forward" {
  description = "Command to access the Flask web app"
  value       = "kubectl port-forward --address 0.0.0.0 service/web 5000:5000"
}
