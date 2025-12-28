# =================================================================================
# Module: dns/root/variables
# =================================================================================
# Purpose: Input variables for Root DNS module
# =================================================================================

variable "root_domain" {
  type        = string
  description = "Root domain name"
  default     = "chs4150.me"
}

variable "dev_domain" {
  type        = string
  description = "Dev subdomain for delegation"
  default     = "dev.chs4150.me"
}

variable "dev_name_servers" {
  type        = list(string)
  description = "Dev Hosted Zone Name Servers (from Dev Account)"
}
