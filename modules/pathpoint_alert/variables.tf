variable "accountId" { type = string }
variable "policyId" { type = string }
variable "stage" { type = string }
variable "name" { type = string }
variable "state" { type = string }
variable "tags" {
  type        = map(list(string))
  default     = {}
  description = "Tags to apply to the alert condition"
}
variable "minute_threshold" {
  type        = number
  default     = 3
  description = "Minutes past the hour threshold for alert triggering"
}
variable "critical_value" {
  type        = number
  default     = 10
  description = "Value returned when state is critical"
}
variable "warning_value" {
  type        = number
  default     = 8
  description = "Value returned when state is warning"
}
variable "normal_value" {
  type        = number
  default     = 1
  description = "Value returned when state is normal"
}