locals {
  # Build pathpoint JSON for each flow
  pathpoint_jsons = {
    for flow_idx, flow in var.flows : flow_idx => {
      id              = local.flow_ids[flow_idx]
      kpis            = []
      name            = flow.name
      refreshInterval = 60000
      stepRowOverride = false
      stages = [
        for stage_idx, stage in flow.stages : {
          id   = local.stage_ids["${flow_idx}::${stage_idx}"]
          name = stage.stage
          link = ""
          related = stage_idx == 0 ? {
            target = true
            } : {
            source = true
            target = true
          }
          levels = [
            for level_idx, level in stage.levels : {
              id = level.id != null ? level.id : uuidv5("dns", "${local.flow_ids[flow_idx]}::${local.stage_ids["${flow_idx}::${stage_idx}"]}::level-${level_idx}")
              steps = [
                for step_idx, step in level.steps : {
                  id      = step.id != null ? step.id : uuidv5("dns", "${local.flow_ids[flow_idx]}::${local.stage_ids["${flow_idx}::${stage_idx}"]}::level-${level_idx}::step-${step_idx}")
                  title   = step.title
                  queries = []
                  signals = [
                    for signal_idx, signal in step.signals : {
                      guid = signal.guid != null ? signal.guid : (
                        module.pathpoint_alert[
                          "${local.flow_ids[flow_idx]}::${local.stage_ids["${flow_idx}::${stage_idx}"]}::${local.signal_ids["${flow_idx}::${stage_idx}::${level_idx}::${step_idx}::${signal_idx}"].signal_id}"
                        ].entity_guid
                      )
                      name     = signal.name
                      included = true
                      type     = signal.type
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  }
}

output "pathpoint_jsons" {
  value       = local.pathpoint_jsons
  description = "PathPoint JSON configurations for all flows"
}

output "pathpoint_json_files" {
  value = {
    for flow_idx, flow in var.flows :
    flow_idx => "${path.module}/pathpoint-${replace(lower(replace(replace(flow.name, ":", ""), " ", "-")), "--", "-")}.json"
  }
  description = "Paths to the generated PathPoint JSON files"
}

output "pathpoint_summary" {
  value = join("\n", [
    "==============================================",
    "Generated PathPoint Configuration Files:",
    "==============================================",
    join("\n", [
      for flow_idx, flow in var.flows :
      format("  %s\n    → %s",
        flow.name,
        "${path.module}/pathpoint-${replace(lower(replace(replace(flow.name, ":", ""), " ", "-")), "--", "-")}.json"
      )
    ])
  ])
  description = "Summary of generated PathPoint JSON files with flow names and filenames"
}
