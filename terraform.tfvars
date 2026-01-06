flows = [
  {
    name                = "Flow Name Here"
    incident_preference = "PER_CONDITION"
    tags = {
      demo = ["tag-value-here"]
    }
    timing = {
      minute_threshold = 5  # Trigger 5 minutes after the hour
      critical_value   = 15 # Return 15 for critical
      warning_value    = 12 # Return 12 for warning
      normal_value     = 2  # Return 2 for normal (and at other times)
    }
    stages = [
      {
        stage = "Stage One"
        levels = [

          { // Level 1
            steps = [
              {
                title = "Example Step"
                signals = [
                  {
                    name  = "Golden Journey Signal"
                    state = "normal"
                  },
                ]
              }
            ]
          },
        ]
       } 
    ]
  }
]