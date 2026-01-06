variable "flows" {
  type = list(object({
    id                  = optional(string)
    name                = string
    incident_preference = optional(string, "PER_CONDITION")
    tags                = optional(map(list(string)), {})
    timing = optional(object({
      minute_threshold = optional(number, 3)
      critical_value   = optional(number, 10)
      warning_value    = optional(number, 8)
      normal_value     = optional(number, 1)
      }), {
      minute_threshold = 3
      critical_value   = 10
      warning_value    = 8
      normal_value     = 1
    })
    stages = list(object({
      id    = optional(string)
      stage = string
      levels = optional(list(object({
        id = optional(string)
        steps = list(object({
          id    = optional(string)
          title = string
          signals = list(object({
            name  = string
            state = optional(string)
            type  = optional(string, "alert")
            guid  = optional(string)
          }))
        }))
      })), [])
      # Legacy support
      alerts = optional(list(object({
        name  = string
        state = string
      })), [])
    }))
  }))
  default     = []
  description = "List of PathPoint flows with stages. Supports both new nested format (levels/steps/signals) and legacy format (alerts). Optional 'id' fields can be provided for flows, stages, levels, and steps to ensure stability when names change. Signals can specify: (1) 'type' field ('entity' or 'alert', defaults to 'alert') for the PathPoint JSON; (2) 'guid' field to reference an existing entity instead of creating an alert (when provided, no alert condition is created and 'state' is not required); (3) 'state' field (required for alerts, optional for entities). Optional 'timing' object can be configured at the flow level to control NRQL alert timing: minute_threshold (default 3), critical_value (default 10), warning_value (default 8), normal_value (default 1). Tags are applied to all alert conditions in the flow."
}

variable "config" {
  type = list(object({
    stage = string
    alerts = list(object({
      name  = string
      state = string
    }))
  }))
  default     = []
  description = "DEPRECATED: Use 'flows' variable instead. Legacy configuration for a single flow."
}

variable "accountId" {
  type        = string
  description = "New Relic account ID"
}