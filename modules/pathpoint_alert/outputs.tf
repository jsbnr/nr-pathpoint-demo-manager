output "entity_guid" {
  value       = newrelic_nrql_alert_condition.nrql_condition.entity_guid
  description = "The entity GUID of the alert condition"
}
