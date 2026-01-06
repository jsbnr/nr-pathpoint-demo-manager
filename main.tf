
# Create a local variable that merges old and new config formats
locals {
  # Generate stable IDs for flows
  flow_ids = {
    for idx, flow in var.flows :
    idx => flow.id != null ? flow.id : uuidv5("dns", "flow-${idx}")
  }

  # Generate stable IDs for stages with flow context
  stage_ids = {
    for item in flatten([
      for flow_idx, flow in var.flows : [
        for stage_idx, stage in flow.stages : {
          flow_idx = flow_idx
          stage_idx  = stage_idx
          flow_id  = local.flow_ids[flow_idx]
          stage_id   = stage.id != null ? stage.id : uuidv5("dns", "${local.flow_ids[flow_idx]}::stage-${stage_idx}")
        }
      ]
    ]) : "${item.flow_idx}::${item.stage_idx}" => item.stage_id
  }

  # Generate stable IDs for signals across the entire structure
  signal_ids = {
    for item in flatten([
      for flow_idx, flow in var.flows : [
        for stage_idx, stage in flow.stages : [
          for level_idx, level in stage.levels : [
            for step_idx, step in level.steps : [
              for signal_idx, signal in step.signals : {
                flow_idx  = flow_idx
                stage_idx   = stage_idx
                level_idx   = level_idx
                step_idx    = step_idx
                signal_idx  = signal_idx
                flow_id   = local.flow_ids[flow_idx]
                stage_id    = local.stage_ids["${flow_idx}::${stage_idx}"]
                signal_id   = uuidv5("dns", "${local.flow_ids[flow_idx]}::${local.stage_ids["${flow_idx}::${stage_idx}"]}::level-${level_idx}::step-${step_idx}::signal-${signal_idx}")
                signal_name = signal.name
              }
            ]
          ]
        ]
      ]
    ]) : "${item.flow_idx}::${item.stage_idx}::${item.level_idx}::${item.step_idx}::${item.signal_idx}" => item
  }

  # If flows is provided, use it; otherwise create a single flow from legacy config
  effective_flows = length(var.flows) > 0 ? var.flows : (
    length(var.config) > 0 ? [
      {
        id                  = null
        name                = "Pathpoint: Pizza Delivery Journey"
        incident_preference = "PER_CONDITION"
        tags                = {}
        timing = {
          minute_threshold = 3
          critical_value   = 10
          warning_value    = 8
          normal_value     = 1
        }
        stages = [
          for stage_idx, stage_config in var.config : {
            id     = null
            stage  = stage_config.stage
            levels = []
            alerts = stage_config.alerts
          }
        ]
      }
    ] : []
  )

  # Create a map of unique flows for resource creation
  # Use stable flow IDs as keys instead of names
  flow_map = {
    for idx, flow in var.flows :
    local.flow_ids[idx] => flow
  }

  # Flatten the flows → stages → levels → steps → signals structure
  # Supports new nested format (levels/steps/signals)
  # Key format: "flow-id::stage-id::signal-id" using stable UUIDs
  # Only creates alerts for signals without a user-provided GUID (entities are excluded)
  alert_map = {
    for item in flatten([
      for flow_idx, flow in var.flows : [
        for stage_idx, stage in flow.stages : [
          for level_idx, level in stage.levels : [
            for step_idx, step in level.steps : [
              for signal_idx, signal in step.signals : signal.guid == null ? {
                flow_idx          = flow_idx
                stage_idx           = stage_idx
                level_idx           = level_idx
                step_idx            = step_idx
                signal_idx          = signal_idx
                flow_id           = local.flow_ids[flow_idx]
                stage_id            = local.stage_ids["${flow_idx}::${stage_idx}"]
                signal_id           = local.signal_ids["${flow_idx}::${stage_idx}::${level_idx}::${step_idx}::${signal_idx}"].signal_id
                flow_name         = flow.name
                incident_preference = flow.incident_preference
                tags                = flow.tags
                timing              = flow.timing
                stage               = stage.stage
                alert_name          = signal.name
                state               = signal.state
              } : null
            ]
          ]
        ]
      ]
    ]) : item != null ? "${item.flow_id}::${item.stage_id}::${item.signal_id}" : "" => item if item != null
  }
}

# Create multiple alert policies (one per flow)
resource "newrelic_alert_policy" "policy" {
  for_each = local.flow_map

  name                = "Pathpoint ${each.value.name}"
  incident_preference = each.value.incident_preference
}

# Create alert conditions for all flows
module "pathpoint_alert" {
  for_each = local.alert_map

  source           = "./modules/pathpoint_alert"
  accountId        = var.accountId
  policyId         = newrelic_alert_policy.policy[each.value.flow_id].id
  stage            = each.value.stage
  name             = each.value.alert_name
  state            = each.value.state
  tags             = each.value.tags
  minute_threshold = each.value.timing.minute_threshold
  critical_value   = each.value.timing.critical_value
  warning_value    = each.value.timing.warning_value
  normal_value     = each.value.timing.normal_value
}

# Generate PathPoint JSON configuration files (one per flow)
resource "local_file" "pathpoint_config" {
  for_each = local.pathpoint_jsons

  content  = jsonencode(each.value)
  filename = "${path.module}/pathpoint-${replace(lower(replace(replace(replace(var.flows[each.key].name, "/", "-"), ":", ""), " ", "-")), "--", "-")}.json"
}