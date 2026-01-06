locals {
  state_value = var.state == "critical" ? var.critical_value : (var.state == "warning" ? var.warning_value : var.normal_value)
}

resource "newrelic_nrql_alert_condition" "nrql_condition" {
  account_id                   = var.accountId
  policy_id                    = var.policyId
  type                         = "static"
  name                         = "${var.name}"
  enabled                      = true
  violation_time_limit_seconds = 3600

  fill_option          = "static"
  fill_value           = 0

  aggregation_window             = 30
  expiration_duration            = 60
  aggregation_method             = "event_flow"
  #aggregation_method             = "event_timer"
  #aggregation_timer = 60
  aggregation_delay              = 60
  open_violation_on_expiration   = false
  close_violations_on_expiration = true

  nrql {
    query = "From Transaction select latest(if(numeric(toDateTime(timestamp,'mm')) > ${var.minute_threshold}, ${local.state_value}, ${var.normal_value}))"
  }

  critical {
    operator              = "above"
    threshold             = var.critical_value - 1
    threshold_duration    = 60
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = var.warning_value - 1
    threshold_duration    = 60
    threshold_occurrences = "at_least_once"
  }

}

resource "newrelic_entity_tags" "alert_tags" {
  count = length(var.tags) > 0 ? 1 : 0
  guid  = newrelic_nrql_alert_condition.nrql_condition.entity_guid

  dynamic "tag" {
    for_each = var.tags
    content {
      key    = tag.key
      values = tag.value
    }
  }
}
