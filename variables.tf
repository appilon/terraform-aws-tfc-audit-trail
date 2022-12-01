variable "region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-1"
}

variable "tfc-audit-trail-url" {
  type        = string
  description = "TFC Audit Trail endpoint to poll."
  default     = "https://app.terraform.io/api/v2/organization/audit-trail"
}

variable "TFC_ORG_TOKEN" {
  type        = string
  description = "TFC Organization Token required for authentication."
  sensitive   = true
}

variable "scrape-interval-secs" {
  type        = number
  description = "Interval between Vector requests in seconds."
  default     = 30
}

variable "page-size" {
  type        = number
  description = "Max results to return in the Audit Trail API request."
  default     = 1000
}

variable "deduplication-cache-size" {
  type        = number
  description = "Number of entries allocated to the deduplication cache, good idea to have it larger than page-size."
  default     = 5000
}
