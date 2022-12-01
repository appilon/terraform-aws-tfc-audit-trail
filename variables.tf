variable "region" {
  type    = string
  default = "us-east-1"
}

variable "tfc-audit-trail-url" {
  type    = string
  default = "https://app.terraform.io/api/v2/organization/audit-trail"
}

variable "TFC_ORG_TOKEN" {
  type      = string
  sensitive = true
}

variable "scrape-interval-secs" {
  type    = number
  default = 30
}

variable "page-size" {
  type    = number
  default = 1000
}

variable "deduplication-cache-size" {
  type    = number
  default = 5000
}
