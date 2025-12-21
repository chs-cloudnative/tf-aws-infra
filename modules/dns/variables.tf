# =================================================================================
# Module: dns/variables
# =================================================================================
# Purpose: Input variables for DNS module
# =================================================================================

variable "domain_name" {
  type        = string
  description = "Domain name for the application"
}

variable "load_balancer_dns_name" {
  type        = string
  description = "Application Load Balancer DNS name"
}

variable "load_balancer_zone_id" {
  type        = string
  description = "Application Load Balancer zone ID"
}
