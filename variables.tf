
variable "kubernetes-dashboard-name" {
  type    = string
  default = "kubernetes-dashboard"
}

variable "app-selector" {
  type    = string
  default = "k8s-app"
}

# Get admin token to authenticate in kubernetes dashboard UI
output "admin-token" {
  value = nonsensitive(kubernetes_secret_v1.admin-user.data.token)
}

# kubectl proxy & 